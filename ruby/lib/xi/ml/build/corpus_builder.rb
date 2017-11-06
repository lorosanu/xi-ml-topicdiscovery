# encoding: utf-8



# Build corpus: divide a given corpus into 3 subcorpus [train, dev, test]
class Xi::ML::Build::CorpusBuilder < Xi::ML::Tools::Component
  attr_reader :input, :name, :to_shuffle, :size, :division

  # Initialize and execute the corpus builder
  #
  # @param input [String] the name of the input json file
  # @param shuffle [Boolean] whether or not to shuffle data (load into memory)
  def initialize(input, shuffle=true)
    super()
    Xi::ML::Tools::Utils.check_file_readable!(input)

    @name = Xi::ML::Tools::Utils.basename(input)
    @input = input
    @to_shuffle = shuffle

    get_corpus_size(input)
    @logger.info("Available input data has #{@size} documents")
  end

  # Count the number of documents in the input file
  #
  # @param input [String] the name of the input json file
  def get_corpus_size(input)
    @size = 0
    File.open(input, 'r').each_line do |line|
      line.chomp!
      @size += 1 unless line.empty?
    end
  end

  # Create and save the [train, dev, test] data sets
  #
  # @param output [Hash] where to save each dataset
  # param division [Hash] the division percentages [dataset: percentage]
  # param limit [Integer] the limited corpus size (optional)
  def build(output, division = { train: 80, dev: 10, test: 10 }, limit = nil)
    raise Xi::ML::Error::ConfigError, \
      "Objects '#{output}' and '#{division}' should have the same structure" \
      unless division.keys.sort == output.keys.sort

    @logger.info("Build #{division.keys} corpora from the #{@input} file")
    @logger.info("Generate a corpus of #{@size} total documents")

    # limit the corpus size if requested
    @size = limit unless limit.nil? || limit >= @size

    # set division counts from percentages
    setup_division(division)

    @logger.info("Output files location: #{output}")

    if @to_shuffle
      # extract random documents
      corpus = Xi::ML::Corpus::PullCorpus.new(@input)

      @division.each do |subset, subset_size|
        # recover 'subset_size' random samples from reference corpus
        next if subset_size == 0

        output_file = output[subset]
        Xi::ML::Tools::Utils.create_path(output_file)

        subcorpus = Xi::ML::Corpus::PushCorpus.new(output_file)
        subcorpus.add_docs(corpus.sample_and_remove(subset_size))
        subcorpus.close_stream()

        @logger.info("Resulting #{subset.to_s.rjust(5)} data set has " \
          "#{subcorpus.size} documents")
      end
    else
      # extract consecutive documents
      corpus = Xi::ML::Corpus::StreamCorpus.new(@input)
      loop_corpus = corpus.each_doc

      @division.each do |subset, subset_size|
        # recover 'subset_size' samples from reference corpus
        next if subset_size == 0

        output_file = output[subset]
        Xi::ML::Tools::Utils.create_path(output_file)

        subcorpus = Xi::ML::Corpus::PushCorpus.new(output_file)
        subset_size.times{ subcorpus.add(loop_corpus.next) }
        subcorpus.close_stream()

        @logger.info("Resulting #{subset.to_s.rjust(5)} data set has " \
          "#{subcorpus.size} documents")
      end
    end
  end

  # Setup the division numbers based on corpus size
  #
  # param division [Hash] the division percentages [dataset: percentage]
  def setup_division(percentages)
    @logger.info(
      "Use the division percentages: #{percentages} (#{@size} total documents)")

    # transform percentages into numbers
    @division = {}
    percentages.each do |subset, percentage|
      @division[subset] = (percentage * @size / 100).to_i
    end

    @logger.info("Use the division counts: #{@division}")
  end

  private :setup_division
end
