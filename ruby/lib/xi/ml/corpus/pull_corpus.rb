# encoding: utf-8



# The basic ML corpus: containing an arrays of hashes
# - 'pull' corpus: loads data into memory
# - is loaded from input json file
# - mainly used to load existing corpus, extract sub-sets of documents
class Xi::ML::Corpus::PullCorpus < Xi::ML::Tools::Component
  attr_reader :input, :content

  # Initialize the corpus
  #
  # @param input [String] input json file
  def initialize(input)
    super()
    @logger.info('Load corpus from file')
    Xi::ML::Tools::Utils.check_file_readable!(input)

    @input = input
    @content = []

    @timer.start_timer

    begin
      File.open(@input, 'r').each_line do |line|
        @content << JSON.load(line)
      end
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when reading JSON '#{@input}' file: #{e.message}"
    else
      @timer.stop_timer("Loaded #{@content.size} docs")
    end

    raise Xi::ML::Error::DataError, "Empty data in JSON file '#{@input}'" \
      if @content.empty?
  end

  # Generate and return 'n' samples of documents
  #
  # @param n [Integer] the samples size
  # @return [Array] a list of n random documents
  def sample(n)
    samples = n > 0 ? @content.sample(n) : []
    samples
  end

  # Generate and return 'n' samples of documents; remove them from corpus
  #
  # @param n [Integer] the samples size
  # @return [Array] a list of n random documents
  def sample_and_remove(n)
    samples = sample(n)
    @content -= samples
    samples
  end

  # Return corpus size
  def size
    @content.size
  end

  # Remove contents
  def unload
    @content.clear
  end

  # Display contents
  def to_s
    @content
  end

end
