# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class PunctCleanerTest < Minitest::Unit::TestCase
  def setup
    @cleaner = Xi::ML::Preprocess::Cleaner::PunctCleaner.new()
  end

  def test_letters
    assert_equal 'hello world', @cleaner.clean('hello world')
  end

  def test_digits
    assert_equal '12 334 423523 543534', @cleaner.clean('12 334 423523 543534')
  end

  def test_letters_digits
    assert_equal 'ggrgr ew454ogsgksg9 78 78', \
      @cleaner.clean('ggrgr ew454ogsgksg9 78 78')
  end

  def test_accents
    assert_equal 'après ça École', @cleaner.clean('après ça École')
  end

  def test_non_latin
    assert_equal 'après ça   École          ', \
      @cleaner.clean('après ça 🚨 École 😱😱😱 😱🇫🇷 🔴')
  end

  def test_apostrophe
    assert_equal "c' est quoi", @cleaner.clean("c'est quoi")
  end

  def test_punctuation_v1
    assert_equal 'Bonjour   Comment vas tu  ', \
      @cleaner.clean('Bonjour ! Comment vas tu ?')
  end

  def test_punctuation_v2
    assert_equal 'Bonjour                               Comment vas tu ', \
      @cleaner.clean("Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?")
  end

end
