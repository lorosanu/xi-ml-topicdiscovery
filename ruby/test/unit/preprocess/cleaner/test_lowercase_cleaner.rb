# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class LowercaseCleanerTest < Minitest::Unit::TestCase
  def setup
    @cleaner = Xi::ML::Preprocess::Cleaner::LowercaseCleaner.new()
  end

  def test_letters
    assert_equal 'hello world', @cleaner.clean('Hello world')
  end

  def test_digits
    assert_equal '12 334 423523 543534', @cleaner.clean('12 334 423523 543534')
  end

  def test_letters_digits
    assert_equal 'ggrgr ew454ogsgksg9 78 78 t', \
      @cleaner.clean('GgrGr eW454OgsgKsg9 78 78 T')
  end

  def test_accents
    assert_equal 'après ça école', @cleaner.clean('Après ça École')
  end

  def test_apostrophe
    assert_equal "c'est quoi", @cleaner.clean("C'Est Quoi")
  end

  def test_punctuation_v1
    assert_equal 'bonjour ! comment vas tu ?', \
      @cleaner.clean('Bonjour ! Comment vas tu ?')
  end

  def test_punctuation_v2
    assert_equal "bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ comment vas tu?", \
      @cleaner.clean("Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?")
  end

  def test_symbols
    assert_equal '€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ', \
      @cleaner.clean('€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ')
  end

end
