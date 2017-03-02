# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class WhitespaceCleanerTest < Minitest::Unit::TestCase
  def setup
    @cleaner = Xi::ML::Preprocess::Cleaner::WhitespaceCleaner.new()
  end

  def test_letters
    assert_equal 'hello world', @cleaner.clean("hello \s \t \n world")
  end

  def test_digits
    assert_equal '12 334 423523 543534', \
      @cleaner.clean("12\t334\s423523    543534")
  end

  def test_letters_digits
    assert_equal 'ggrgr ewogsgksg', \
      @cleaner.clean("\t ggrgr ewogsgksg \n")
  end

  def test_accents
    assert_equal 'après ça École', @cleaner.clean("après ça\tÉcole")
  end

  def test_apostrophe
    assert_equal "c'est quoi", @cleaner.clean("   c'est  \t  quoi  \t\t ")
  end

  def test_punctuation_v1
    assert_equal 'Bonjour ! Comment vas tu ?', \
      @cleaner.clean('Bonjour !  Comment vas tu ?')
  end

  def test_punctuation_v2
    assert_equal "Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?", \
      @cleaner.clean("Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?")
  end

end
