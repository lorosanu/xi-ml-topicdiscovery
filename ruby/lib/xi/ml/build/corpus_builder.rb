# encoding: utf-8



# Build corpus: divide a given corpus into 3 subcorpus [train, dev, test]
class Xi::ML::Build::CorpusBuilder < Xi::ML::Tools::Component
  attr_reader :name, :division, :size, :corpus, :datasets

  # Initialize and execute the corpus builder
  #
  # @param input [String] the name of the input json file
  def initialize(input)
    super()
    Xi::ML::Tools::Utils.check_file_readable!(input)

    @logger.info("Build {train, dev, test} corpora from the #{input} file")
    @name = Xi::ML::Tools::Utils.basename(input)
    @corpus = Xi::ML::Corpus::PullCorpus.new(input)
    @logger.info("Available input data has #{@corpus.size} documents")
  end

  # Setup the division numbers based on corpus size
  def setup_division
    raise Xi::ML::Error::ConfigError, 'Bad division format: '\
      + 'not a Hash object with [:train, :dev, :test] keys' \
      unless @division.is_a?(Hash) && @division.keys == [:train, :dev, :test]

    @logger.info("Use the division percentages: #{@division}")

    # transform percentages into numbers
    @division.each do |subset, percentage|
      @division[subset] = (percentage * @size / 100).to_i
    end

    @logger.info("Use the division numbers: #{@division}")
  end

  # Create and save the [train, dev, test] data sets
  #
  # @param output [Hash] where to save each dataset
  # param division [Hash] the division percentages [dataset: percentage]
  # param limit [Integer] the limited corpus size (optional)
  def build(output, division = { train: 80, dev: 10, test: 10 }, limit = nil)

    # limit the corpus size if requested
    @corpus = @corpus.sample(limit) unless limit.nil? || limit >= @corpus.size
    @size = corpus.size

    @logger.info("Generate a corpus of #{@size} total documents")

    # recover division numbers from percentages
    @division = division.clone
    setup_division()

    @logger.info("Output files location: #{output}")

    # build and save datasets
    @datasets = {}
    @division.each do |subset, subset_size|
      output_file = output[subset.to_s]
      Xi::ML::Tools::Utils.create_path(output_file)

      # recover 'subset_size' random samples from reference corpus
      @datasets[subset] = Xi::ML::Corpus::PushCorpus.new(output_file)
      @datasets[subset].add_docs(@corpus.sample_and_remove(subset_size))
      @datasets[subset].close_stream()

      @logger.info("Resulting #{subset.to_s.rjust(5)} data set has " \
        "#{@datasets[subset].size} documents")
    end
  end

  private :setup_division
end
