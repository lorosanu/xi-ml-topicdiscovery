# encoding: utf-8



# LogisticRegression classifier
class Xi::ML::Classify::LRClassifier < Xi::ML::Tools::Component
  attr_reader :input, :conf, :probas

  OPTIONS = %w[name n_classes n_features classes coefs intercept].freeze

  # Initialize the LogisticRegression classifier
  #
  # @param input [String] the file storing the classifier's configuration
  def initialize(input='')
    super()

    Xi::ML::Tools::Utils.check_file_readable!(input)
    @input = input

    load_config()
    @logger.info('Loaded already trained LR classifier')
  end

  # Load the classifier's parameters
  def load_config
    begin
      @conf = JSON.load(File.read(@input))

      raise Xi::ML::Error::ConfigError, "No data found in JSON file #{@input}"\
        if @conf.empty?

      raise Xi::ML::Error::ConfigError, "JSON object stored in '#{@input}' "\
        + 'is not a HASH' \
        unless @conf.is_a?(Hash)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of YAML file #{@input}: #{e.message}"
    end

    raise Xi::ML::Error::ConfigError, \
      "Given configuration '#{@conf}' doesn't match '#{OPTIONS}' structure" \
      unless @conf.keys.sort == OPTIONS.sort

    raise Xi::ML::Error::ConfigError, \
      'Invalid classifier model: '\
      "not equal dimensions between coefficients (#{@conf['coefs'].size}) "\
      "and classes (#{@conf['n_classes']})" \
      if @conf['n_classes'] > 2 && @conf['coefs'].size != @conf['classes'].size
  end

  # Predict class for a new document
  #
  # @param doc [String] the list of features separated by spaces
  # @return [Hash] the most likely class and the class probabilities
  def classify_doc(doc='')
    raise Xi::ML::Error::ConfigError, 'Method expects a String object'\
      unless doc.is_a?(String)

    { probas: predict_proba(doc), category: predict_class(doc) }
  end

  # Predict the class probabilities of the given document
  #
  # @param doc [String] given document
  # @return [Hash] the class => prob information
  def predict_proba(doc)
    @probas = {}

    return {} if doc.empty?

    features = []
    doc.split(' ').each {|x| features << x.to_f }

    raise Xi::ML::Error::DataError, \
      "Document must contain #{@conf['n_features']} features "\
      + "instead of #{features.size} features"\
      if features.size != @conf['n_features']

    # special format for the 2-class classifier
    if @conf['n_classes'] == 2
      # coefs: matrix form [1 x n_features]
      # intercept: matrix form [1 x n_features]

      coefs = @conf['coefs'][0]
      intercept = @conf['intercept'][0]

      # lr_prob => the class probability of the second class
      prob = lr_prob(features, coefs, intercept)

      @probas = {}
      @probas[@conf['classes'][1]] = prob
      @probas[@conf['classes'][0]] = (1.0 - prob).round(7)
      return @probas
    end

    if @conf['n_classes'] > 2
      # coefs: matrix form [n_classes x n_features]
      # intercept: matrix form [n_classes x n_features]

      @probas = {}
      @conf['coefs'].each_with_index do |class_coefs, index|
        category = @conf['classes'][index]
        intercept = @conf['intercept'][index]

        # lr_prob => the current class probability
        @probas[category] = lr_prob(features, class_coefs, intercept)
      end

      # normalize probabilities (sum > 1.0)
      sum_p = @probas.values.reduce {|sum, wx| sum + wx }
      @probas = @probas.map{|category, pb| [category, pb / sum_p] }.to_h
      return @probas
    end

    {}
  end

  # Compute the LR's fx probability
  def lr_prob(features, coefs, intercept)
    # sum = w0 * x0 + w1 * x1 + ...
    sum = 0
    coefs.zip(features){|w, x| sum += w * x }

    # add intercept
    fx = sum + intercept

    prob = 1.0 / (1.0 + Math.exp(-1 * fx))
    prob.round(7)
  end

  # Predict the document's most likely class based on class probabilities
  #
  # @param doc [String] given document
  # @return [String] the most likely class
  def predict_class(doc)
    predict_proba(doc) if @probas.empty?

    # no features => no probabilities => category not available
    return '_NA_' if @probas.empty?

    @probas.key(@probas.values.max)
  end

  private :load_config, :lr_prob
end
