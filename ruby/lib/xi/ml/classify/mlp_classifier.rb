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
    values.size.times{|i| values[i] = 0 if values[i] < 0 }
    values
  end

  def self.softmax(values)
    max_value = values.max

    sum = 0
    values.each{|x| sum += Math.exp(x - max_value) }

    values.map{|x| Math.exp(x - max_value) / sum }
  end

  def self.logistic(values)
    values.map{|x| (1.0 / (1.0 + Math.exp(-1.0 * x))) }
  end
end

# Multi-layer Perceptron classifier
class Xi::ML::Classify::MLPClassifier < Xi::ML::Tools::Component
  attr_reader :model

  OPTIONS = %w(name classifier_type classes n_classes n_features
    hidden_layers hidden_activation
    output_layer output_activation).freeze

  ACTIVATIONS = {
    'tanh' => Xi::ML::Classify::Activation.method('tanh'),
    'relu' => Xi::ML::Classify::Activation.method('relu'),
    'softmax' => Xi::ML::Classify::Activation.method('softmax'),
    'logistic' => Xi::ML::Classify::Activation.method('logistic'),
    'identity' => Xi::ML::Classify::Activation.method('identity'),
  }.freeze

  # Initialize the LogisticRegression classifier
  #
  # @param input [String] the file storing the classifier's configuration
  def initialize(input)
    super()

    Xi::ML::Tools::Utils.check_file_readable!(input)

    # load the classifier's parameters
    begin
      @model = JSON.load(File.read(input))
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of YAML file #{input}: #{e.message}"
    end

    # check configuration
    raise Xi::ML::Error::ConfigError, \
      "No data found in JSON file #{input}"\
      if @model.empty?

    raise Xi::ML::Error::ConfigError, \
      "JSON object stored in '#{input}' is not a HASH" \
      unless @model.is_a?(Hash)

    raise Xi::ML::Error::ConfigError, \
      "Given configuration '#{@model.keys.sort}' "\
      "doesn't match '#{OPTIONS.sort}' structure" \
      unless @model.keys.sort == OPTIONS.sort

    [@model['hidden_activation'], @model['output_activation']].each do |fc|
      raise Xi::ML::Error::ConfigError, "Unknown activation function '#{fc}'" \
        unless ACTIVATIONS.key?(fc)
    end

    # convert model coefficients to nvector format
    @model['hidden_layers'].size.times do |i|
      @model['hidden_layers'][i] = NVector.to_na(@model['hidden_layers'][i])
    end

    @model['output_layer'] = NVector.to_na(@model['output_layer'])

    @logger.info('Loaded already trained MLP classifier')
  end

  # Predict the class probabilities of the given document
  #
  # @param features [Array] the list of float features
  # @return [Hash] the most likely class and the class probabilities
  # { :category => class, :probas => {class => prob} }
  def classify_doc(features)
    return { category: '_NA_', probas: {} } if features.empty?

    raise Xi::ML::Error::DataError, \
      "Document must contain #{@model['n_features']} features "\
      + "instead of #{features.size} features"\
      if @model['n_features'] != features.size

    outputs = compute_mlp_probabilities(features)

    probas = {}

    # special format for the 2-class classifier
    if @model['n_classes'] == 2 && @model['classifier_type'] == 'multiclass'
      raise Xi::ML::Error::DataError, \
        "Expected an output layer with 1 value instead of '#{outputs.size}'" \
        if outputs.size != 1

      # output contains the document's probability of belonging to the 2nd class
      probas[@model['classes'][1]] = outputs[0]
      probas[@model['classes'][0]] = 1.0 - outputs[0]
    else
      # associate a class name for each class probabilities from 'outputs'
      probas = @model['classes'].zip(outputs).to_h
    end

    # get most probable category (having maximum probability)
    category = '_NA_'
    unless probas.empty?
      max = probas.values[0]
      category = probas.keys[0]

      probas.each do |k, v|
        if v > max
          max = v
          category = k
        end
      end
    end

    { category: category, probas: probas }
  end

  # Compute the probabilities in all MLP layers
  # @param features [Array] the MLP's input values
  # @return [Array] the MLP's output values
  def compute_mlp_probabilities(features)

    # process hidden layers (intercepts already included in coeffs)
    # - new_layer = sum(prev_layer[i] * coefs[i])
    # - new_layer = apply_activation(activation function, new_layer)

    layer = features.clone

    @model['hidden_layers'].each do |coeffs|
      # add bias
      layer << 1.0
      layer = NVector.to_na(layer)

      layer *= coeffs
      layer = ACTIVATIONS[@model['hidden_activation']].call(layer.to_a)
    end

    # process output layer
    # - in case of a 2-class classification => 1 node in the output layer
    # - in case of a n-class (n > 2) classification => 'n' nodes in output layer

    layer << 1.0
    layer = NVector.to_na(layer)
    layer *= @model['output_layer']
    layer = ACTIVATIONS[@model['output_activation']].call(layer.to_a)

    layer
  end

  private :compute_mlp_probabilities
end
