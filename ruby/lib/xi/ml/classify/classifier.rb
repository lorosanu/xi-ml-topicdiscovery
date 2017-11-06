# encoding: utf-8



# Document classifier:
# apply 'sklearn' classifier model on new/test documents
class Xi::ML::Classify::Classifier < Xi::ML::Tools::Component
  attr_reader :name, :model

  NOCLASS = '_NA_'.freeze
  CLASSIFIERS = {
    LogisticRegression: Xi::ML::Classify::LRClassifier,
    MLPClassifier: Xi::ML::Classify::MLPClassifier,
  }.freeze

  # Initialize the classifier
  #
  # @param clas_name [String] the name of the classifier model to use
  # @param clas_file [String] the file storing the classifier's configuration
  def initialize(clas_name, clas_file)
    super()

    raise Xi::ML::Error::ConfigError, \
      "Unknown model '#{clas_name}'. Choose from #{CLASSIFIERS.keys}" \
      unless CLASSIFIERS[clas_name]

    @name = clas_name
    @model = CLASSIFIERS[@name].new(clas_file)
  end

  # Predict class for a new document
  #
  # @param doc [Array] the list of the document's float features
  # @return [Hash] the most likely class and the class probabilities
  def classify_doc(doc)
    @model.classify_doc(doc)
  end

  # Classify each document in a given corpus
  #
  # @param data_file [String] file of json corpus with documents features
  # @param output_file [String] file of json corpus with 'season'&'season_prob'
  def store_classification(data_file, output_file)
    Xi::ML::Tools::Utils.check_file_readable!(data_file)
    Xi::ML::Tools::Utils.create_path(output_file)

    @logger.info("Processing documents from #{data_file}")
    @timer.start_timer()

    sc = Xi::ML::Corpus::StreamCorpus.new(data_file)
    pc = Xi::ML::Corpus::PushCorpus.new(output_file)

    sc.each_doc do |doc|
      if doc['features']
        prediction = @model.classify_doc(doc['features'])

        # add two new fields into each document entry
        doc['season'] = prediction[:category]
        doc['season_prob'] = prediction[:probas]
        pc.add(doc)
      end
    end

    @timer.stop_timer(
      "Saved #{pc.size} classified documents into #{output_file}")

    pc.close_stream()
  end
end
