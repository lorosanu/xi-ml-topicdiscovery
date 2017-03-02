# encoding: utf-8


# The basic ML corpus: containing an arrays of hashes
# - 'stream' corpus: do not load data into memory; yield each document
# - recover each document from json file while reading line by line
# - mainly used to loop through documents
class Xi::ML::Corpus::StreamCorpus < Xi::ML::Tools::Component
  attr_reader :input

  # Initialize the corpus
  #
  # @param input [String] the name of the input txt file
  def initialize(input)
    super()
    Xi::ML::Tools::Utils.check_file_readable!(input)
    @input = input
    @logger.info("Corpus will look into documents from '#{input}' file")
  end

  # Loop through documents
  def each_doc
    @logger.info('Loop through documents')

    # do not fail in case of missing block, return an iterator
    return enum_for(__method__) unless block_given?

    begin
      File.open(@input, 'r').each_line do |line|
        doc = JSON.load(line)
        yield doc
      end
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when creating doc hash object: #{e.message}"
    end
  end

end
