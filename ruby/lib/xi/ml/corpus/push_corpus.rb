# encoding: utf-8



# The basic ML corpus: containing an arrays of hashes with @keys keys
# - 'push' corpus: add data directly to file without loading it into memory
# - opens an empty file and adds one or more documents at a time
# - mainly used to create and save new corpus
# - note: remember to close the file stream at the end
class Xi::ML::Corpus::PushCorpus < Xi::ML::Tools::Component
  attr_reader :keys, :size, :ofstream

  # Initialize the corpus
  #
  # @param output [String] name of the output json file
  # @param keys [Array] array of accepted keys for data corpus (optional)
  def initialize(output, keys = %w[id url title content category])
    super()
    raise Xi::ML::Error::ConfigError, 'Given output is not a String' \
      unless output.is_a?(String)

    @logger.info('Initialized empty corpus')
    @logger.info("Save new corpus in '#{output}' file")

    Xi::ML::Tools::Utils.create_path(output)
    @ofstream = File.open(output, 'w')
    @keys = keys.clone
    @size = 0
  end

  # Add a document to corpus
  #
  # @param doc [Hash] the document to add into the corpus
  def add(doc)
    check_right_doc_format!(doc)

    @ofstream.puts(doc.to_json)
    @size += 1
  end

  # Add a list of documents to corpus
  #
  # @param docs [Array] the list of documents to add into the corpus
  def add_docs(docs)
    raise Xi::ML::Error::ConfigError, 'Given input is not an Array' \
      unless docs.is_a?(Array)

    docs.each {|doc| add(doc) }
  end

  # Close file stream
  def close_stream
    @ofstream.close()
  end

  # Check if input document is a hash object with @keys keys
  #
  # @param doc [Hash] a document of type Hash with @keys keys
  def check_right_doc_format!(doc)
    unless doc.is_a?(Hash) && doc.keys.sort == @keys.sort
      @ofstream.close()
      raise Xi::ML::Error::ConfigError, \
        "Bad document format: not a Hash object with #{@keys} keys" \
    end
  end

  private :check_right_doc_format!
end
