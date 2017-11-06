# encoding: utf-8



# Document transformer (feature extraction):
# apply 'gensim' transformation model(s) on preprocessed documents
class Xi::ML::Transform::LSITransformer < Xi::ML::Tools::Component
  attr_reader :dictionary, :tfidf_params, :lsi_params, :n_topics

  MODELS = [:dict, :tfidf, :lsi].freeze

  # Initialize the LSI transformer
  #
  # @param trans_files [Hash] the files needed for the LSI transformation
  def initialize(trans_files)
    super()

    raise Xi::ML::Error::ConfigError, \
      "Bad input '#{trans_files}'. Expected a Hash object with #{MODELS} keys" \
      unless trans_files.is_a?(Hash) && MODELS.sort == trans_files.keys.sort

    @logger.info("Loading already trained LSI models from #{trans_files}")

    @timer.start_timer()
    trans_files.each do |trans_name, trans_file|
      Xi::ML::Tools::Utils.check_file_readable!(trans_file)
      @logger.info("Load #{trans_name}")
      self.__send__("load_#{trans_name}", trans_file)
    end
    @timer.stop_timer('Models loaded')
  end

  # Private method to load the dictionary
  def load_dict(file)
    begin
      @dictionary = JSON.load(File.read(file))

      raise Xi::ML::Error::ConfigError,
        "No data in JSON file '#{file}'" \
        if @dictionary.empty?

      raise Xi::ML::Error::ConfigError, \
        "JSON object stored in '#{file}' is not a Hash" \
        unless @dictionary.is_a?(Hash)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when reading file '#{file}': #{e.message}"
    end
  end

  # Private method to load the TF-IDF pre-trained model
  # an array of IDF weights (array index == word_id)
  def load_tfidf(file)
    begin
      tfidf_array = JSON.load(File.read(file))

      raise Xi::ML::Error::ConfigError,
        "No data in JSON file '#{file}'" \
        if tfidf_array.empty?

      raise Xi::ML::Error::ConfigError, \
        "JSON object stored in '#{file}' is not an Array" \
        unless tfidf_array.is_a?(Array)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of JSON file '#{file}' : #{e.message}"
    end

    @tfidf_params = Numo::DFloat.new(tfidf_array.size)
    @tfidf_params.store(tfidf_array)
  end

  # Private method to load the LSI pre-trained model
  # an array of LSI topic weights (array index == word_id)
  def load_lsi(file)
    lsi_array = Xi::ML::Tools::ModelBinarizer.revert(file)
    @n_topics = lsi_array[0].size

    @lsi_params = Numo::DFloat.new(lsi_array.size, @n_topics)
    @lsi_params.store(lsi_array)
  end

  # Transform the given document into the LSI format
  #
  # @param text [String] the document's content
  # @return [Array] the document's features list
  def transform_doc(text)
    raise Xi::ML::Error::ConfigError, 'Input data is not a String object' \
      unless text.is_a?(String)

    # compute known word frequencies: word_id => word_frequency
    freq = {}
    freq.default = 0

    text.split.each do |word|
      freq[@dictionary[word]] += 1 if @dictionary.key?(word)
    end

    return [] if freq.empty?

    # list of word ids
    ids = freq.keys

    # compute and normalize TF-IDF features
    tfidf_weights = Numo::DFloat[*freq.values] * @tfidf_params.slice(ids)
    tfidf_weights /= Math.sqrt((tfidf_weights**2).sum)

    # recover LSI weights for current document
    lsi_weights = @lsi_params.slice(ids, (0..-1))

    # compute LSI features
    (tfidf_weights.dot(lsi_weights)).to_a
  end

  private :load_dict, :load_tfidf, :load_lsi
end
