# encoding: utf-8



# LogisticRegression classifier
class Xi::ML::Classify::LRClassifier < Xi::ML::Tools::Component
  attr_reader :input, :probas, \
    :classes, :n_classes, :n_features, \
    :coeffs, :intercept

  STRUCTURE = %w[name n_classes n_features classes coeffs intercept].freeze

  # Initialize the LogisticRegression classifier
  #
  # @param input [String] the file storing the classifier's configuration
  def initialize(input='')
    super()

    Xi::ML::Tools::Utils.check_file_readable!(input)
    @input = input

    load_model_parameters()
    @logger.info('Loaded already trained LR classifier')
  end

  # Load the classifier's parameters
  def load_model_parameters
    params = {}

    begin
      params = JSON.load(File.read(@input))

      raise Xi::ML::Error::ConfigError, \
        "No data found in JSON file #{@input}" \
        if params.empty?

      raise Xi::ML::Error::ConfigError, \
        "JSON object stored in '#{@input}' is not a HASH" \
        unless params.is_a?(Hash)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of JSON file #{@input}: #{e.message}"
    end

    raise Xi::ML::Error::ConfigError, \
      "Given parameters '#{params}' do not match '#{STRUCTURE}' structure" \
      unless params.keys.sort == STRUCTURE.sort

    raise Xi::ML::Error::ConfigError, \
      'Invalid classifier model: '\
      "not equal dimensions between coefficients (#{params['coeffs'].size}) " \
      "and classes (#{params['n_classes']})" \
      if params['n_classes'] > 2 \
        && params['coeffs'].size != params['classes'].size

    # store parameters
    @n_classes = params['n_classes']
    @n_features = params['n_features']
    @classes = params['classes']
    @coeffs = params['coeffs'].map{|x| Numo::DFloat[*x] }
    @intercept = params['intercept']

    params.clear()
  end

  # Predict class for a new document
  #
  # @param doc [Array] the list of float features
  # @return [Hash] the most likely class and the class probabilities
  def classify_doc(doc)
    { probas: predict_proba(doc), category: predict_class(doc) }
  end

  # Predict the class probabilities of the given document
  #
  # @param features [Array] given document's features
  # @return [Hash] the class => prob information
  def predict_proba(features)
    @probas = {}
    return {} if features.empty?

    raise Xi::ML::Error::DataError, \
      "Document must contain #{@n_features} features "\
      "instead of #{features.size} features"\
      if @n_features != features.size

    # special format for the 2-class classifier
    if @n_classes == 2
      # coeffs: matrix form [1 x n_features]
      # intercept: matrix form [1 x n_features]

      # lr_prob => the class probability of the second class
      prob = lr_prob(features, @coeffs[0], @intercept[0])

      @probas = {
        @classes[1] => prob,
        @classes[0] => (1.0 - prob).round(7),
      }

      return @probas
    end

    if @n_classes > 2
      # coeffs: matrix form [n_classes x n_features]
      # intercept: matrix form [n_classes x n_features]

      @probas = {}
      @coeffs.each_with_index do |class_coeffs, index|
        category = @classes[index]
        intercept = @intercept[index]

        # lr_prob => the current class probability
        @probas[category] = lr_prob(features, class_coeffs, intercept)
      end

      # normalize probabilities (sum > 1.0)
      sum_p = @probas.values.reduce {|sum, wx| sum + wx }
      @probas = @probas.map{|category, pb| [category, pb / sum_p] }.to_h

      return @probas
    end

    {}
  end

  # Compute the LR's fx probability
  def lr_prob(features, coeffs, intercept)
    # sum = w0 * x0 + w1 * x1 + ...
    sum = (Numo::DFloat[*features] * coeffs).sum

    # add intercept and negate
    fx = -(sum + intercept)

    prob = 1.0 / (1.0 + Math.exp(fx))
    prob.round(7)
  end

  # Predict the document's most likely class based on class probabilities
  #
  # @param doc [Array] given document's features
  # @return [String] the most likely class
  def predict_class(doc)
    predict_proba(doc) if @probas.empty?

    # no features => no probabilities => category not available
    return Xi::ML::Classify::Classifier::NOCLASS if @probas.empty?

    @probas.key(@probas.values.max)
  end

  private :load_model_parameters, :lr_prob
end
