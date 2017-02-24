# encoding: utf-8



# Multi-layer Perceptron classifier
class Xi::ML::Classify::MLPClassifier < Xi::ML::Tools::Component
  attr_reader :input, :conf, :layer, :probas

  OPTIONS = %w(name classifier_type classes n_classes n_features
    hidden_layers hidden_activation
    output_layer output_activation).freeze

  # Initialize the LogisticRegression classifier
  #
  # @param input [String] the file storing the classifier's configuration
  def initialize(input='')
    super()

    Xi::ML::Tools::Utils.check_file_readable!(input)
    @input = input

    load_config()
    @logger.info('Loaded already trained MLP classifier')
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

      raise Xi::ML::Error::ConfigError, \
        "Given configuration '#{@conf.keys.sort}' "\
        "doesn't match '#{OPTIONS.sort}' structure" \
        unless @conf.keys.sort == OPTIONS.sort
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of YAML file #{@input}: #{e.message}"
    end

    # convert model coefficients to nvector format
    @conf['hidden_layers'].each do |hidden_layer|
      hidden_layer.map!{|weights| NVector.to_na(weights) }
    end

    @conf['output_layer'].map!{|weights| NVector.to_na(weights) }
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
  # @param doc [String] given document's features
  # @return [Hash] the class => prob information
  def predict_proba(doc)
    @probas = {}

    return {} if doc.empty?

    # initialize the first layer: the input features
    @layer = doc.split.map{|x| x.to_f }

    raise Xi::ML::Error::DataError, \
      "Document must contain #{@conf['n_features']} features "\
      + "instead of #{@layer.size} features"\
      if @conf['n_features'] != @layer.size

    outputs = compute_mlp_probabilities()

    # special format for the 2-class classifier
    if @conf['n_classes'] == 2 && @conf['classifier_type'] == 'multiclass'
      raise Xi::ML::Error::DataError, \
        'Expected one value in the output layer of a 2-class classification.'\
        "Found '#{outputs}' probabilities." \
        if outputs.size != 1

      # output contains 1 value:
      # the document's probability of belonging to the second class

      @probas = {}
      @probas[@conf['classes'][1]] = outputs[0]
      @probas[@conf['classes'][0]] = (1.0 - outputs[0]).round(7)
      return @probas
    else
      # associate a class name for each class probabilities from 'outputs'
      @probas = @conf['classes'].zip(outputs).to_h
      return @probas
    end

    {}
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

  # Compute the probabilities in all MLP layers
  #
  # @return [Array] the MLP's output values
  def compute_mlp_probabilities

    # check if input layer initialized
    return [] if @layer.empty?

    # process hidden layers (intercepts already included in coeffs)
    # - new_layer = sum(prev_layer[i] * coefs[i])
    # - new_layer = apply_activation(activation function, new_layer)

    @conf['hidden_layers'].each do |coeffs|
      @layer = process_layer(coeffs, @conf['hidden_activation'])
    end

    # process output layer
    # - in case of a 2-class classification => 1 node in the output layer
    # - in case of a n-class (n > 2) classification => 'n' nodes in output layer

    @layer = process_layer(@conf['output_layer'], @conf['output_activation'])
    @layer.map!{|x| x.round(7) }

    @layer
  end

  # Compute the probabilities for current layer
  # layer = w0 * x0 + w1 * x1 + ...
  # layer = activation(layer)
  def process_layer(coeffs, function)
    # add bias weight on features
    @layer << 1.0

    # convert to NVector format
    feat = NVector.to_na(@layer)

    # compute the dot product between features and coeffs
    begin
      values = coeffs.map{|weights| feat * weights }
    rescue => e
      raise Xi::ML::Error::CaughtException,\
        "Exception encountered when executing the dot product: #{e.message}"
    end

    # apply activation function
    case function
    when 'identity'
      # f(x) = x
      return values
    when 'tanh'
      # f(x) = tanh(x)
      return values.map{|x| Math.tanh(x) }
    when 'relu'
      # f(x) = max(0, x)
      return values.map{|x| [0, x].max }
    when 'softmax'
      # f(x) = softmax(x)
      max_value = values.max

      sum = 0
      values.each{|x| sum += Math.exp(x - max_value) }

      return values.map{|x| Math.exp(x - max_value) / sum }
    when 'logistic'
      # f(x) = 1 / (1 + exp(-x))
      return values.map{|x| (1.0 / (1.0 + Math.exp(-1.0 * x))) }
    else
      raise Xi::ML::Error::ConfigError, \
        "Unknown activation function '#{function}'"
    end
  end

  private :load_config, :compute_mlp_probabilities, :process_layer
end
