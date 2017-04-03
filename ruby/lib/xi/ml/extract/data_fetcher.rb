# encoding: utf-8



# Process query on ES client, store results
class Xi::ML::Extract::DataFetcher < Xi::ML::Tools::Component
  attr_reader :search, :keys, :fields, :min_nchars

  STRIP_URL = %w[http https www com fr co uk htm html php js].freeze

  # Initialize the data fetcher: connect the ES client
  #
  # @param host [String] the hostname of the ES server
  # @param port [String] the port of the ES server
  # @param keys [Array] the fields to store (optional)
  def initialize(host, port, keys = %w[id url title content category])
    super()
    @logger.info('Initialize the data fetcher')
    @search = Xi::ML::Extract::ESSearch.new(host, port)
    @keys = keys.clone
  end

  # Setup the search options
  #
  # @param category [String] the category of documents to extract
  # @param indexes [Array] the list of ES indexes
  # @param types [Array] the list of ES types
  # @param source [Array] recover these fields for each document
  # @param query [String] recover documents matching this query
  # @param min_nchars [int] recover documents of minimum this size (#chars)
  # @param output [String] the file where to store the results
  def search_and_save(category:'',
    indexes:[], types:[],
    source:%w[id site url lang title content],
    query:nil, min_nchars: 200,
    output:nil)

    @fields = source.clone
    @min_nchars = min_nchars
    corpus = Xi::ML::Corpus::PushCorpus.new(output, @keys)

    # store SHA256(content) to check for repeating contents
    hvalues = {}

    ndocs = 0
    counts = {}
    counts.default = 0

    @timer.start_timer()

    indexes.each do |index|
      types.each do |type|

        # setup a new search for each index and for each type
        @search.search_setup(
          index: index,
          type: type,
          source: @fields,
          query: query,
        )

        begin
          # scroll results (yield => loop)
          @search.scroll do |search_entry|
            current_entry = process_result(search_entry)
            next if current_entry.size == 0

            save_entry = current_entry.select {|k, _| @keys.include?(k) }
            save_entry['category'] = category

            content = current_entry['content']
            unless hvalues.key?(Digest::SHA256.hexdigest(content))
              corpus.add(save_entry)
            end
            hvalues[Digest::SHA256.hexdigest(content)] = 1

            # debug information
            if ndocs == 0
              @logger.debug("Current entry: #{save_entry}")
              @logger.debug("Current entry keys: #{save_entry.keys}")
              @logger.debug("Current entry values: #{save_entry.values}")
            end

            ndocs += 1
            counts[current_entry['site']] += 1
            @logger.info("Extracted #{ndocs} documents") if ndocs % 100_000 == 0
          end
        rescue => e
          raise Xi::ML::Error::CaughtException, \
            "Exception encountered when scrolling results #{e.message}"
        end
      end
    end

    corpus.close_stream

    # log info
    @timer.stop_timer("Documents retrieved from #{counts.size} host names")
    @logger.info("#{corpus.size} / #{ndocs} unique documents will be stored")

    counts = Hash[counts.sort_by {|_, value| value }.reverse]
    @logger.info("Number of documents retrieved per url:\n#{PP.pp(counts, '')}")
  end

  # Process the es_search results
  #
  # @param doc [Hash] the ES hash entry
  # @return [Hash] return the processed entry
  def process_result(doc)
    entry = {}

    @fields.each do |field|
      case field
      when 'id'
        entry['id'] = doc['_id'] if doc['_id']
      when 'lang'
        entry['lang'] = doc['_source']['lang'] if doc['_source']['lang']
      when 'url'
        entry['url'] = doc['_source']['url'] if doc['_source']['url']
      when 'site'
        entry['site'] = doc['_source']['site'].join('.') \
          if doc['_source']['site']
      when 'title'
        entry['title'] = doc['_source']['title'] if doc['_source']['title']
      when 'content'
        entry['content'] = ''

        # include words from url and from title
        if doc['_source']['url'] && doc['_source']['title']
          url = UnicodeUtils.downcase(doc['_source']['url'])
          title = UnicodeUtils.downcase(doc['_source']['title'])

          words = Xi::ML::Tools::Formatter.words_from_url(url).split()
          words.concat(title.split())
          words.uniq!

          entry['content'] << words.join(' ') << ' '
        end

        # include content
        entry['content'] << doc['_source']['content'] \
          if doc['_source']['content']

        # replace possible 'new line' characters with a dot
        entry['content'].gsub!(/\n\r/, '. ')
        entry['content'].gsub!(/\n/, '. ')
      when 'content_analyzed'
        # recover array of [word, stem, pos]
        if doc['_source']['content_analyzed']
          nlp = doc['_source']['content_analyzed']
          entry['content_nlp'] = Xi::ML::Tools::Formatter.words_from_nlp(nlp)
        end
      else
        @logger.warn("Unknown requested field '#{field}'. "\
          'You should add a new feature to the gem. '\
          'Otherwise it will always be empty')
        entry[field.to_s] = ''
      end
    end

    # store only contents of minimum '@min_nchars' characters
    entry = {} if entry['content'].size < @min_nchars

    # return processed entry
    entry
  end

  private :process_result
end
