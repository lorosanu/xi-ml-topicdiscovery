# encoding: utf-8



# The basic ML corpus: containing an arrays of documents hashes
# - 'push' corpus: add data directly to file without loading it into memory
# - opens an empty file and adds one or more documents at a time
# - mainly used to create and save new corpus
# - note: remember to close the file stream at the end
class Xi::ML::Corpus::PushCorpus < Xi::ML::Tools::Component
  attr_reader :size, :ofstream

  # Initialize the corpus
  #
  # @param output [String] name of the output json file
  def initialize(output)
    super()

    @logger.info('Initialized empty corpus')
    @logger.info("Save new corpus in '#{output}' file")

    Xi::ML::Tools::Utils.create_path(output)
    @ofstream = File.open(output, 'w')

    # use .sync = true for nlp preprocessing
    @ofstream.sync = true

    @size = 0
  end

  # Add a document to corpus
  #
  # @param doc [Hash] the document to add into the corpus
  def add(doc)
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
end
