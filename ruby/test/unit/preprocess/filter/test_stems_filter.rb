# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class StemsFilterTest < Minitest::Unit::TestCase
  def setup
    @filter_stems = Xi::ML::Preprocess::Filter::OnlyStemsFilter.new()
    @filter_stems_n = Xi::ML::Preprocess::Filter::PosNFilter.new()
    @filter_stems_nv = Xi::ML::Preprocess::Filter::PosNVFilter.new()

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

  def test_stems_letters
    cdata = 'antonio a officialis mercred la prolong du bail de greg popovich .'
    assert_equal cdata, @filter_stems.filter(@data_letters)
  end

  def test_stems_letters_digits
    cdata = 'diabat ( 36 ) et hoarau ( 72 ) ont marqu le girondin .'
    assert_equal cdata, @filter_stems.filter(@data_letters_digits)
  end

  def test_stems_posn_letters
    cdata = 'antonio mercred prolong bail greg popovich'
    assert_equal cdata, @filter_stems_n.filter(@data_letters)
  end

  def test_stems_posn_letters_digits
    cdata = 'diabat hoarau girondin'
    assert_equal cdata, @filter_stems_n.filter(@data_letters_digits)
  end

  def test_stems_posnv_letters
    cdata = 'antonio a officialis mercred prolong bail greg popovich'
    assert_equal cdata, @filter_stems_nv.filter(@data_letters)
  end

  def test_stems_posnv_letters_digits
    cdata = 'diabat hoarau ont marqu girondin'
    assert_equal cdata, @filter_stems_nv.filter(@data_letters_digits)
  end
end
