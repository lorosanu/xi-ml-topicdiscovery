# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class LemmasFilterTest < Minitest::Unit::TestCase
  def setup
    @filter_lemmas = Xi::ML::Preprocess::Filter::OnlyLemmasFilter.new()
    @filter_lemmas_n = Xi::ML::Preprocess::Filter::PosNLemmasFilter.new()
    @filter_lemmas_nv = Xi::ML::Preprocess::Filter::PosNVLemmasFilter.new()

    @data_letters = [
      ['Antonio', 'NPP', nil, 'antonio'],
      ['a', 'V', 'avoir', 'a'],
      ['officialisé', 'VPP', 'officialiser', 'officialis'],
      ['mercredi', 'NC', 'mercredi', 'mercred'],
      ['la', 'DEL', 'le', 'la'],
      ['prolongation', 'NC', 'prolongation', 'prolong'],
      ['du', 'P+D', 'de', 'du'],
      ['bail', 'NC', 'bail', 'bail'],
      ['de', 'P', 'de', 'de'],
      ['Greg', 'NPP', nil, 'greg'],
      ['Popovich', 'NPP', nil, 'popovich'],
      ['.', 'PONCT', nil, '.'],
    ]

    @data_letters_digits = [
      ['Diabate', 'NPP', nil, 'diabat'],
      ['(', 'PONCT', nil, '('],
      ['36', 'DET', nil, '36'],
      [')', 'PONCT', nil, ')'],
      ['et', 'CC', 'et', 'et'],
      ['Hoarau', 'NPP', nil, 'hoarau'],
      ['(', 'PONCT', nil, '('],
      ['72', 'DET', nil, '72'],
      [')', 'PONCT', nil, ')'],
      ['ont', 'V', 'avoir', 'ont'],
      ['marqué', 'VPP', 'marquer', 'marqu'],
      ['les', 'DET', 'le', 'le'],
      ['Girondins', 'NPP', nil, 'girondin'],
      ['.', 'PONCT', nil, '.'],
    ]
  end

  def test_lemmas_letters
    cdata = 'Antonio avoir officialiser mercredi le prolongation '\
      'de bail de Greg Popovich .'
    assert_equal cdata, @filter_lemmas.filter(@data_letters)
  end

  def test_lemmas_letters_digits
    cdata = 'Diabate ( 36 ) et Hoarau ( 72 ) avoir marquer le Girondins .'
    assert_equal cdata, @filter_lemmas.filter(@data_letters_digits)
  end

  def test_lemmas_posn_letters
    cdata = 'Antonio mercredi prolongation bail Greg Popovich'
    assert_equal cdata, @filter_lemmas_n.filter(@data_letters)
  end

  def test_lemmas_posn_letters_digits
    cdata = 'Diabate Hoarau Girondins'
    assert_equal cdata, @filter_lemmas_n.filter(@data_letters_digits)
  end

  def test_lemmas_posnv_letters
    cdata = 'Antonio avoir officialiser mercredi prolongation bail '\
      'Greg Popovich'
    assert_equal cdata, @filter_lemmas_nv.filter(@data_letters)
  end

  def test_lemmas_posnv_letters_digits
    cdata = 'Diabate Hoarau avoir marquer Girondins'
    assert_equal cdata, @filter_lemmas_nv.filter(@data_letters_digits)
  end
end
