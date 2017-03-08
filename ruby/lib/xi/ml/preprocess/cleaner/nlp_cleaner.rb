# encoding: utf-8


require 'xi/nlp'
require 'xi/nlp/opennlp'
require 'xi/nlp/lingua'
require 'xi/nlp/morphalou'


# The NLP cleaner: uses the 'xi-nlp' gem
# Preprocesses the input data in various ways:
#   * extracts stems
#   * filters POS tags [NC, NP, NPP, V, VS, VINF, VPP, VPR, VIMP]
#   * ...
class Xi::ML::Preprocess::Cleaner::NLPCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  attr_reader :logger, :lang, :filter, :nlp_workflow, :processed_docs

  CONFIG = 'conf/xi_nlp.yml'.freeze

  # Initialize the NLP cleaner
  #
  # @param lang [String] which language of NLP models to use
  # @param filter [Filter] which filter object to apply
  def initialize(lang:nil, filter:nil)
    @logger = Xi::ML::Tools::Logger.create(self.class.name.downcase)
    checkups(lang, filter)

    @lang = lang
    @filter = Object.const_get(filter).new()

    @processed_docs = 0
    @nlp_workflow = load_nlp()
  end

  # Apply NLP processing
  #
  # @param text [String] the text on which to apply the NLP filter
  # @return [String] the filtered text
  def clean(text)
    doc = Xi::NLP::Base::Document.new({ '' => { text: text } })
    @nlp_workflow.analyze(doc, timing: false)

    # recover tokens, stems and postags from nlp workflow
    annotations = doc.instance_variable_get(:@annotations)
      .instance_variable_get(:@data)

    tokens = annotations[:tokens] ? annotations[:tokens] : []
    postags = annotations[:postags] ? annotations[:postags] : []
    lemmas = annotations[:lemmas] ? annotations[:lemmas] : []
    stems = annotations[:stems] ? annotations[:stems] : []

    clean_text = ''

    # output the data within the desired format
    unless tokens.empty?
      @processed_docs += 1

      data = tokens.zip(postags, lemmas, stems)
      clean_text = @filter.filter(data)

      # display debugging information
      nlp_example(data, clean_text) if @processed_docs == 1

      # reload NLP every 50k documents => avoid OOM errors
      reload_nlp() if @processed_docs % 50_000 == 0
    end

    clean_text
  end

  # Checkup the input arguments for valid content
  def checkups(lang, filter)
    raise Xi::ML::Error::ConfigError, 'Nil argument(s)' \
      if lang.nil? || filter.nil?

    languages = Xi::ML::Preprocess::Language.known()
    filters = Xi::ML::Preprocess::Filter::AbstractFilter.descendants_names()

    raise Xi::ML::Error::ConfigError, \
      "Unknown language '#{lang}'. Choose from #{languages}" \
      unless languages.include?(lang)

    raise Xi::ML::Error::ConfigError, \
      "Unknown filter '#{filter}'. Choose from #{filters}" \
      unless filters.include?(filter)
  end

  # Initialize NLP variables
  def load_nlp
    Xi::NLP::Config.load_yaml(CONFIG)
    Xi::NLP.load()

    lang_workflow = Xi::NLP::Base::AnalysisWorkflow.new([
      Xi::NLP::OpenNLP::Tokenizer.new(@lang),
      Xi::NLP::OpenNLP::PosTagger.new(@lang),
      Xi::NLP::Morphalou::Lemmatizer.new(@lang),
      Xi::NLP::Lingua::SnowballStemmer.new(@lang),
    ].map {|ac| ac.workflow })

    workflow = Xi::NLP::Base::AnalysisWorkflow.new([
      Xi::NLP::Generic::SmoothText.new().workflow,
      Xi::NLP::OpenNLP::SentenceDetector.new(@lang).workflow,
      Xi::NLP::Base::MapAnalysisWorkflow.new([lang_workflow], merge: true),
    ])

    workflow
  end

  # Reloading NLP and NLP variables
  def reload_nlp
    @logger.info('Reloading NLP')
    Xi::NLP.unload()
    @nlp_workflow = load_nlp()
  end

  # Debug information
  def nlp_example(data, clean_text)
    @logger.info('Example of NLP Processing:')
    data.each do |token, tag, lemma, stem|
      @logger.info("token=#{token} pos=#{tag} lemma=#{lemma} stem=#{stem}")
    end
    @logger.info("Resulting output: #{clean_text}")
  end

  private :checkups, :nlp_example, :load_nlp, :reload_nlp
end
