# encoding: utf-8



# Document transformer (feature extraction):
# apply 'gensim' transformation model(s) on preprocessed documents
class Xi::ML::Transform::Transformer < Xi::ML::Tools::Component
  attr_reader :name, :model

  TRANSFORMERS = {
    LSI: Xi::ML::Transform::LSITransformer
  }.freeze

  # Initialize the transformer
  #
  # @param trans_name [Symbol] the name of the transformation model
  # @param trans_files [Hash] the files needed for the transformation
  def initialize(trans_name, trans_files)
    super()

    raise Xi::ML::Error::ConfigError, \
      "Unknown model name '#{trans_name}'. Choose from #{TRANSFORMERS.keys}" \
      unless TRANSFORMERS.key?(trans_name)

    @name = trans_name
    @model = TRANSFORMERS[@name].new(trans_files)
  end

  # Transform the given document into the given format
  #
  # @param text [String] the document's content
  # @return [Array] the document's features
  def transform_doc(text)
    @model.transform_doc(text)
  end

  # Transform given corpus into given format
  #
  # @param data_file [String] the file of json corpus with reference documents
  # @param output_file [String] the file of json corpus with new features field
  def store_transformation(data_file, output_file)
    Xi::ML::Tools::Utils.check_file_readable!(data_file)
    Xi::ML::Tools::Utils.create_path(output_file)

    @logger.info("Processing documents from '#{data_file}'")

    sc = Xi::ML::Corpus::StreamCorpus.new(data_file)
    pc = Xi::ML::Corpus::PushCorpus.new(output_file)

    sc.each_doc do |doc|
      if doc['content']
        doc['features'] = @model.transform_doc(doc['content'])
        pc.add(doc)
      end
    end

    @logger.info("Saved #{pc.size} documents into '#{output_file}'")
    pc.close_stream()
  end
end
