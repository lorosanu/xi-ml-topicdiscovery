# encoding: utf-8



# Clean corpus: apply several cleaners on the input data
class Xi::ML::Preprocess::CorpusCleaner < Xi::ML::Tools::Component
  attr_reader :cleaners, :corpus

  def initialize(cleaners = [])
    super()
    init_cleaners(cleaners)
  end

  # Initialize the cleaning objects
  #
  # @param cleaners (Array) list of cleaners (hash of name and arguments)
  def init_cleaners(cleaners = [])

    # checkups
    cnames = Xi::ML::Preprocess::Cleaner::AbstractCleaner.descendants_names

    # each cleaner's hash
    cleaners.each do |cleaner|
      raise Xi::ML::Error::ConfigError, \
        "Bad cleaner format '#{cleaner}'; missing [:name, :args] values" \
        unless cleaner.is_a?(Hash) && cleaner.keys == [:name, :args]
      raise Xi::ML::Error::ConfigError, \
        "Class for cleaner '#{cleaner[:name]}' not found." \
        unless cnames.include?(cleaner[:name])
    end

    # init cleaning objects
    @cleaners = []
    cleaners.each do |cleaner|        # each cleaner's hash
      cname = cleaner[:name]          # cleaner name
      cargs = cleaner[:args]          # cleaner hash of arguments

      @logger.info("Initializing #{cname}")
      # initialize an object of the given class (try-catch)
      begin
        object = Object.const_get(cname).new(cargs)
        @cleaners << object
      rescue => e
        raise Xi::ML::Error::CaughtException, \
          "Failed to initialize class '#{cname}': #{e.message}"
      end
    end

    raise Xi::ML::Error::DataError, \
      'List of initialized cleaners empty or incomplete' \
      if @cleaners.size != cleaners.size

    @logger.info("Using #{@cleaners.size} cleaners")
  end

  # Apply each cleaner on each document of the input file and store it
  #
  # @param input [String] the input json file
  # @param output [String] the output json file
  def clean(input, output)
    @corpus = Xi::ML::Corpus::StreamCorpus.new(input)
    @clean_corpus = Xi::ML::Corpus::PushCorpus.new(output)

    # clean corpus
    ndocs = 0

    @timer.start_timer()

    @corpus.each_doc do |doc|
      text = doc['content'].chomp()
      @cleaners.each do |cleaner|
        text = cleaner.clean(text)
      end
      doc['content'] = text
      @clean_corpus.add(doc)

      ndocs += 1
      @timer.stop_timer("Processed #{ndocs} documents") if ndocs % 10_000 == 0
    end

    # log info
    @timer.stop_timer("Processed #{ndocs} total documents")
    @logger.info("Stored #{@clean_corpus.size} / #{ndocs} documents")

    # close the output file stream
    @clean_corpus.close_stream
  end

  # Apply each cleaner on each document of the input file and store it
  #
  # @param input [String] the input txt file
  # @param output [String] the output txt file
  def clean_txt(input, output)
    Xi::ML::Tools::Utils.create_path(output)

    File.open(output, 'w') do |of|
      File.read(input).each_line do |line|
        text = line.chomp()
        @cleaners.each do |cleaner|
          text = cleaner.clean(text)
        end
        of.puts(text)
      end
    end
  end

  # Apply each cleaner on one given document
  #
  # @param doc [String] the given document
  # @return [String] the cleaned document
  def clean_doc(doc)
    text = doc.chomp()
    @cleaners.each do |cleaner|
      text = cleaner.clean(text)
    end
    text
  end

  private :init_cleaners

end
