# encoding: utf-8



# Document transformer (feature extraction):
# apply 'gensim' transformation model(s) on preprocessed documents
class Xi::ML::Transform::LSITransformer < Xi::ML::Tools::Component
  attr_reader :dictionary, :tfidf_model, :lsi_model, :n_topics

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
    trans_files.each{|trans_name, trans_file| load(trans_name, trans_file) }
    @timer.stop_timer('Models loaded')
  end

  # Load the pre-trained models
  #
  # @param name [String] the model's name
  # @param file [String] the file storing the model
  def load(name, file)
    return if file == ''
    Xi::ML::Tools::Utils.check_file_readable!(file)

    case name
    when :dict
      @logger.info('Load dictionary')
      load_dict(file)
    when :tfidf
      @logger.info('Load TF-IDF model')
      load_tfidf(file)
    when :lsi
      @logger.info('Load LSI model')
      load_lsi(file)
    end
  end

  # Private method to load the dictionary
  def load_dict(file)
    @dictionary = {}

    begin
      File.open(file, 'r').each_line do |line|
        id, word = line.split(' ')
        @dictionary[word] = id.to_i unless id.nil? && word.nil?
      end
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when reading file '#{file}': #{e.message}"
    end
  end

  # Private method to load the TF-IDF pre-trained model
  def load_tfidf(file)
    @tfidf_model = {}

    begin
      @tfidf_model = JSON.load(File.read(file))
      @tfidf_model = @tfidf_model.map{|k, v| [k.to_i, v.to_f] }.to_h

      raise Xi::ML::Error::ConfigError,
        "No data in JSON file '#{file}'" \
        if @tfidf_model.empty?

      raise Xi::ML::Error::ConfigError, \
        "JSON object stored in '#{file}' is not a HASH" \
        unless @tfidf_model.is_a?(Hash)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of JSON file '#{file}' : #{e.message}"
    end
  end

  # Private method to load the LSI pre-trained model
  def load_lsi(file)
    @lsi_model = Xi::ML::Tools::ModelBinarizer.revert(file)
    @n_topics = @lsi_model.values[0].size
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

    return '' if freq.empty?

    # list of sorted ids
    ids = freq.keys

    # compute TF-IDF features
    tfidf_weights = ids.map{|id| freq[id] * @tfidf_model[id] }
    tfidf_weights = normalize_weights(tfidf_weights)

    # recover LSI weights for current document
    lsi_weights = ids.map{|id| @lsi_model[id] }

    # compute LSI features
    lsi_features = Array.new(@n_topics, 0)

    @n_topics.times do |topic_id|
      ids.size.times do |word_index|
        lsi_features[topic_id] += \
          tfidf_weights[word_index] * lsi_weights[word_index][topic_id]
      end
    end

    lsi_features.join(' ')
  end

  # compute the TF-IDF l2 norm on given weights
  def normalize_weights(weights)
    # compute norm = sqrt(sum_i (x_i * x_i))
    norm = 0
    weights.each {|weight| norm += weight**2 }
    norm = Math.sqrt(norm)

    # normalize by norm
    weights.map!{|weight| weight / norm }
    weights
  end

  private :load_dict, :load_tfidf, :load_lsi, :normalize_weights
end
