# encoding: utf-8


# Activation function calculator
class Xi::ML::Classify::Activation
  def self.identity(values)
    values
  end

  def self.tanh(values)
    values.map{|x| Math.tanh(x) }
  end

  def self.relu(values)
    values[values < 0] = 0.0
    values
  end

  def self.softmax(values)
    values -= values.max
    values = values.map{|x| Math.exp(x) }
    values / values.sum
  end

  def self.logistic(values)
    values.map{|x| (1.0 / (1.0 + Math.exp(-1.0 * x))) }
  end
end

# Multi-layer Perceptron classifier
class Xi::ML::Classify::MLPClassifier < Xi::ML::Tools::Component
  attr_reader :type, :classes, :n_classes, :n_features, \
    :h_layers, :h_intercepts, :h_activ, \
    :o_layer, :o_intercepts, :o_activ

  STRUCTURE = %w(
    name classifier_type classes n_classes n_features
    hidden_coeffs hidden_intercepts hidden_activation
    output_coeffs output_intercepts output_activation).freeze

  ACTIVATIONS = [:tanh, :relu, :softmax, :logistic, :identity].freeze

  # Initialize the LogisticRegression classifier
  #
  # @param input [String] the file storing the classifier's configuration
  def initialize(input)
    super()
    Xi::ML::Tools::Utils.check_file_readable!(input)
    load_model_parameters(input)
    @logger.info('Loaded already trained MLP classifier')
  end

  def load_model_parameters(input)
    params = {}

    begin
      params = JSON.load(File.read(input))

      raise Xi::ML::Error::ConfigError, \
        "No data found in JSON file #{input}" if params.empty?

      raise Xi::ML::Error::ConfigError, \
        "Object stored in '#{input}' is not a HASH" unless params.is_a?(Hash)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of JSON file #{input}: #{e.message}"
    end

    raise Xi::ML::Error::ConfigError, \
      "Given parameters '#{params.keys}' don't match '#{STRUCTURE}' structure" \
      unless params.keys.sort == STRUCTURE.sort

    [params['hidden_activation'], params['output_activation']].each do |fc|
      raise Xi::ML::Error::ConfigError, "Unknown activation function '#{fc}'" \
        unless ACTIVATIONS.include?(fc.to_sym)
    end

    # store parameters
    @type = params['classifier_type']
    @classes = params['classes']
    @n_classes = params['n_classes']
    @n_features = params['n_features']
    @h_activ = params['hidden_activation']
    @o_activ = params['output_activation']

    # convert model coefficients to numo format
    @h_layers = []
    params['hidden_coeffs'].each{|hc| @h_layers << Numo::DFloat[*hc] }

    @h_intercepts = []
    params['hidden_intercepts'].each{|hi| @h_intercepts << Numo::DFloat[*hi] }

    @o_layer = Numo::DFloat[*params['output_coeffs']]
    @o_intercepts = Numo::DFloat[*params['output_intercepts']]

    params.clear()
  end

  # Predict the class probabilities of the given document
  #
  # @param features [Array] the list of float features
  # @return [Hash] the most likely class and the class probabilities
  # { :category => class, :probas => { class => prob } }
  def classify_doc(features)
    return { category: Xi::ML::Classify::Classifier::NOCLASS, probas: {} } \
      if features.empty?

    raise Xi::ML::Error::DataError, \
      "Document must contain #{@n_features} features " \
      "instead of #{features.size} features"\
      if @n_features != features.size

    outputs = compute_mlp_probabilities(features)

    probas = {}

    # special format for the 2-class classifier
    if @n_classes == 2 && @type == 'multiclass'
      raise Xi::ML::Error::DataError, \
        "Expected an output layer with 1 value instead of '#{outputs.size}'" \
        if outputs.size != 1

      # output contains the document's probability of belonging to the 2nd class
      probas = {
        @classes[1] => outputs[0].round(7),
        @classes[0] => (1.0 - outputs[0]).round(7),
      }
    else
      # associate a class name for each class probabilities from 'outputs'
      probas = @classes.zip(outputs).to_h
    end

    # get most probable category (having maximum probability)
    if probas.empty?
      category = Xi::ML::Classify::Classifier::NOCLASS
    else
      category = probas.key(probas.values.max)
    end

    { category: category, probas: probas }
  end

  # Compute the probabilities in all MLP layers
  # @param features [Array] the MLP's input values
  # @return [Array] the MLP's output values
  def compute_mlp_probabilities(features)

    # process hidden layers (coefficients & intercepts)
    # - new_layer = prev_layer[i] * coefs[i] + intercept[i]
    # - new_layer = apply_activation(activation function, new_layer)

    layer = Numo::DFloat[*features]

    @h_layers.each_with_index do |coeffs, index|
      layer = layer.dot(coeffs) + @h_intercepts[index]
      layer = Xi::ML::Classify::Activation.__send__(@h_activ, layer)
    end

    # process output layer
    # - in case of a 2-class classification => 1 node in the output layer
    # - in case of a n-class (n > 2) classification => 'n' nodes in output layer

    layer = layer.dot(@o_layer) + @o_intercepts
    layer = Xi::ML::Classify::Activation.__send__(@o_activ, layer)

    layer.to_a
  end

  private :compute_mlp_probabilities
end
