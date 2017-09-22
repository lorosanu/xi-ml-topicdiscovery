# encoding: utf-8



# Process query on ES client, store results
class Xi::ML::Extract::DataFetcher < Xi::ML::Tools::Component
  attr_reader :search, :es_fields, :corpus_fields, :min_nchars

  # Initialize the data fetcher: connect the ES client
  #
  # @param host [String] the hostname of the ES server
  # @param port [String] the port of the ES server
  # @param keys [Array] the fields to store (optional)
  def initialize(
    host, port, keys = [:id, :url, :site, :title, :content, :category])

    super()
    @logger.info('Initialize the data fetcher')
    @search = Xi::ML::Extract::ESSearch.new(host, port)
    @corpus_fields = keys.dup
  end

  # Setup the search options
  #
  # @param category [Symbol] the category of documents to extract
  # @param indexes [Array] the list of ES indexes
  # @param types [Array] the list of ES types
  # @param source [Array] recover these fields for each document
  # @param queries [Array] recover documents matching any of these queries
  # @param min_nchars [int] recover documents of minimum this size (#chars)
  # @param limit [int] recover a limited number of documents per site
  # @param output [String] the file where to store the results
  def search_and_save(category:, indexes:[], types:[],
    source:[:id, :site, :url, :lang, :title, :content],
    queries:[nil], min_nchars: 200, limit:nil, output:nil)

    @es_fields = source.dup
    @min_nchars = min_nchars
    corpus = Xi::ML::Corpus::PushCorpus.new(output)

    # store SHA256(content) to check for duplicate contents
    checkup = {}

    counts = {}
    ndocs = { saved: 0, limit: 0, long: 0, total: 0 }

    @timer.start_timer()

    queries.each do |query|
      indexes.each do |index|
        types.each do |type|

          # setup a new search for each index and for each type
          @search.search_setup(
            index: index,
            type: type,
            source: @es_fields,
            query: query,
          )

          begin
            # scroll results (yield => loop)
            @search.scroll do |search_entry|
              entry = process_result(search_entry)
              site = entry[:site].sub('www.', '')

              counts[site] = { saved: 0, limit: 0, long: 0, total: 0 } \
                unless counts[site]

              ndocs[:total] += 1
              counts[site][:total] += 1

              # skip documents with empty content
              next if entry[:content].empty?

              ndocs[:long] += 1
              counts[site][:long] += 1

              # skip documents for sites that reached their limit
              next if !limit.nil? && counts[site][:saved] >= limit

              # count duplicates for documents within limit
              ndocs[:limit] += 1
              counts[site][:limit] += 1

              save_entry = entry.select {|k, _| @corpus_fields.include?(k) }
              save_entry[:category] = category.to_s

              raise Xi::ML::Error::DataError, \
                "Extracted document '#{save_entry}' "\
                "does not match required structure '#{@corpus_fields}'" \
                unless save_entry.keys.sort == @corpus_fields.sort

              content_sha = Digest::SHA256.hexdigest(entry[:raw_content])
              unless checkup.key?(content_sha)
                corpus.add(save_entry)

                ndocs[:saved] += 1
                counts[site][:saved] += 1

                checkup[content_sha] = true

                # progress information
                @logger.info("Saved #{ndocs.values.join(' / ')} documents") \
                  if ndocs[:saved] % 100_000 == 0
              end
            end
          rescue => e
            raise Xi::ML::Error::CaughtException, \
              "Exception encountered when scrolling results #{e.message}"
          end
        end
      end
    end

    corpus.close_stream

    # log info
    @timer.stop_timer("Processed documents from #{counts.size} host names")
    @logger.info("Stored #{ndocs.values.join(' / ')} documents")

    counts = Hash[counts.sort_by {|_, value| value[:saved] }.reverse]
    @logger.info("# of total documents per domain:\n#{PP.pp(counts, '')}")

    pshort = (100 - 1.0 * ndocs[:long] / ndocs[:total] * 100).round(2)
    pignored = (100 - 1.0 * ndocs[:limit] / ndocs[:long] * 100).round(2)
    pdup = (100 - 1.0 * ndocs[:saved] / ndocs[:limit] * 100).round(2)

    @logger.info("#{pshort}% docs have less than #{min_nchars} characters")
    @logger.info("#{pignored}% docs ignored due to the #{limit}docs/site limit")
    @logger.info("#{pdup}% docs have duplicates (with respect to saved docs)")
  end

  # Process the es_search results
  #
  # @param doc [Hash] the ES hash entry
  # @return [Hash] return the processed entry
  def process_result(doc)
    entry = {}

    source = {}
    source = doc['_source'] if doc['_source']

    @es_fields.each do |field|
      # default empty value
      entry[field] = ''

      case field
      when :id
        entry[:id] = doc['_id'] if doc['_id']
      when :lang
        entry[:lang] = source['lang'] if source['lang']
      when :url
        entry[:url] = source['url'] if source['url']
      when :site
        if source['site'] && source['site'].is_a?(Array) \
          && !source['site'].empty?

          # adjust to 2 different 'site' configurations
          if source['site'][0].include?('.')
            entry[:site] = source['site'][0]
          else
            entry[:site] = source['site'].join('.')
          end
        end
      when :keywords
        if source['keywords'] && source['keywords'].is_a?(Array) \
          && !source['keywords'].empty?

          entry[:keywords] = source['keywords'].select{|word| word.size < 30 }
          entry[:keywords] = entry[:keywords].uniq.join(' ')
        end
      when :title
        entry[:title] = source['title'] if source['title']
      when :description
        entry[:description] = source['description'] if source['description']
      when :content
        entry[:content] = source['content'] if source['content']
      when :content_analyzed
        # recover array of [word, stem, pos]
        if source['content_analyzed']
          nlp = source['content_analyzed']
          entry[:content_nlp] = Xi::ML::Tools::Formatter.words_from_nlp(nlp)
        end
      else
        @logger.warn("Unknown requested field '#{field}'. "\
          'You should add a new feature to the gem. '\
          'Otherwise it will always be empty')
      end
    end

    # store only contents of minimum '@min_nchars' characters
    if entry[:content].size < @min_nchars
      entry[:content] = ''
      return entry
    end

    # keep a reference content for content duplicate detection
    entry[:raw_content] = entry[:content]

    # include words from url, title and keywords into content
    # when present in the es_fields argument
    words = []

    if entry[:url] && !entry[:url].nil? && !entry[:url].empty?
      url = Unicode.downcase(entry[:url])
      words.concat(Xi::ML::Tools::Formatter.words_from_url(url).split())
    end

    if entry[:title] && !entry[:title].empty?
      title = Unicode.downcase(entry[:title])
      words.concat(title.split())
    end

    if entry[:keywords] && !entry[:keywords].empty?
      keywords = Unicode.downcase(entry[:keywords])
      words.concat(keywords.split())
    end

    unless words.empty?
      words.uniq!
      entry[:content] << ' ' << words.join(' ')
    end

    # replace possible 'new line' characters with a dot
    entry[:content].gsub!(/\n\r/, '. ')
    entry[:content].gsub!(/\n/, '. ')

    # return processed entry
    entry
  end

  private :process_result
end
