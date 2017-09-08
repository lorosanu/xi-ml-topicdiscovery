# encoding: utf-8


require 'minitest/autorun'


$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class ClassifierTest < Minitest::Unit::TestCase

  def setup
    lr_file = File.join(File.dirname(__FILE__), 'example_lr.json')
    mlp_file = File.join(File.dirname(__FILE__), 'example_mlp.json')

    Xi::ML::Tools::Utils.check_file_readable!(lr_file)
    Xi::ML::Tools::Utils.check_file_readable!(mlp_file)

    @lr_classifier = Xi::ML::Classify::Classifier.new(
      :LogisticRegression, lr_file)

    @mlp_classifier = Xi::ML::Classify::Classifier.new(
      :MLPClassifier, mlp_file)

    sport_file = File.join(File.dirname(__FILE__), 'feat_sport.txt')
    nonsport_file = File.join(File.dirname(__FILE__), 'feat_non-sport.txt')

    @doc_sport = File.read(sport_file).split.map{|x| x.to_f }
    @doc_non_sport = File.read(nonsport_file).split.map{|x| x.to_f }
  end

  def test_lr_sport
    probas = @lr_classifier.classify_doc(@doc_sport)
    rprobas = {
      category: 'sport',
      probas: {
        'sport' => 0.9024615677212438,
        'non-sport' => 0.09753843227875625,
      },
    }

    probas[:probas] = probas[:probas].map{|k, v| [k, v.round(6)] }.to_h
    rprobas[:probas] = rprobas[:probas].map{|k, v| [k, v.round(6)] }.to_h

    assert_equal rprobas, probas
  end

  def test_lr_non_sport
    probas = @lr_classifier.classify_doc(@doc_non_sport)
    rprobas = {
      category: 'non-sport',
      probas: {
        'sport' => 0.15439201579094589,
        'non-sport' => 0.8456079842090541,
      },
    }

    probas[:probas] = probas[:probas].map{|k, v| [k, v.round(6)] }.to_h
    rprobas[:probas] = rprobas[:probas].map{|k, v| [k, v.round(6)] }.to_h

    assert_equal rprobas, probas
  end

  def test_mlp_sport
    probas = @mlp_classifier.classify_doc(@doc_sport)
    rprobas = {
      category: 'sport',
      probas: {
        'sport' => 0.9998468666083369,
        'non-sport' => 0.00015313339166311848,
      },
    }

    probas[:probas] = probas[:probas].map{|k, v| [k, v.round(6)] }.to_h
    rprobas[:probas] = rprobas[:probas].map{|k, v| [k, v.round(6)] }.to_h

    assert_equal rprobas, probas
  end

  def test_mlp_non_sport
    probas = @mlp_classifier.classify_doc(@doc_non_sport)
    rprobas = {
      category: 'non-sport',
      probas: {
        'sport' => 0.06101909845389608,
        'non-sport' => 0.9389809015461039,
      },
    }

    probas[:probas] = probas[:probas].map{|k, v| [k, v.round(6)] }.to_h
    rprobas[:probas] = rprobas[:probas].map{|k, v| [k, v.round(6)] }.to_h

    assert_equal rprobas, probas
  end

end
