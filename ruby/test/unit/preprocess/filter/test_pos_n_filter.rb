# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class PosNFilterTest < Minitest::Unit::TestCase
  def setup
    @filter = Xi::ML::Preprocess::Filter::PosNFilter.new()
  end

  def test_letters
    data = [['Face', 'Fac', 'NC'],
             ['à', 'à', 'P'],
             ['la', 'la', 'DET'],
             ['fougue', 'fougu', 'NC'],
             ['de', 'de', 'P'],
             ['Daria', 'Dari', 'NPP'],
             ['Gavrilova', 'Gavrilov', 'NPP'],
             [',', ',', 'PONCT'],
             ['qui', 'qui', 'PROREL'],
             ['s\'', 's\'', 'CLR'],
             ['est', 'est', 'V'],
             ['montrée', 'montr', 'VPP'],
             ['très', 'tres', 'ADV'],
             ['nerveuse', 'nerveux', 'ADJ'],
           ]
    cdata = 'Fac fougu Dari Gavrilov'
    assert_equal cdata, @filter.filter(data)
  end

  def test_letters_digits
    data = [['Suarez', 'Suar', 'VIMP'],
             ['Navarro', 'Navarro', 'NPP'],
             ['(', '(', 'PONCT'],
             ['Esp/10', 'Esp/10', 'NC'],
             [')', ')', 'PONCT'],
             ['-', '-', 'PONCT'],
             ['D.', 'D.', 'NPP'],
             ['Gavrilova', 'Gavrilova', 'NPP'],
             ['(', '(', 'PONCT'],
             ['Aus', 'Aus', 'NPP'],
             [')', ')', 'PONCT'],
             ['0-', '0-', 'PONCT'],
             ['6', '6', 'DET'],
             ['6-', '6-', 'CLS'],
             ['3', '3', 'ADJ'],
             ['3', '3', 'ADJ'],
             [',', ',', 'PONCT'],
             ['6-', '6-', 'PRO'],
             ['2', '2', 'ADJ'],
           ]
    cdata = 'Navarro Esp/10 D. Gavrilova Aus'
    assert_equal cdata, @filter.filter(data)
  end

end
