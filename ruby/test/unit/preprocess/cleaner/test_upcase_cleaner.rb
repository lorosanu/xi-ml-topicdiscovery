# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class UpcaseCleanerTest < Minitest::Unit::TestCase
  def setup
    @cleaner = Xi::ML::Preprocess::Cleaner::UpcaseCleaner.new()
  end

  def test_letters
    assert_equal 'Hello World', @cleaner.clean('HelloWorld')
  end

  def test_digits
    assert_equal '12 334 423523 543534', @cleaner.clean('12 334 423523 543534')
  end

  def test_letters_digits
    assert_equal 'Ggr Gr e W454 Og Sg K Sg9 78 78 T', \
      @cleaner.clean('GgrGr eW454OGSgKSg9 78 78 T')
  end

  def test_accents
    assert_equal 'Après Ça École', @cleaner.clean('Après Ça École')
  end

  def test_apostrophe
    assert_equal "C'EST Quoi", @cleaner.clean("C'EST Quoi")
  end

  def test_punctuation_v1
    assert_equal 'Bonjour ! Comment Vas Tu ?', \
      @cleaner.clean('Bonjour ! CommentVASTu ?')
  end

  def test_punctuation_v2
    assert_equal "Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?", \
      @cleaner.clean("Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?")
  end

  def test_symbols
    assert_equal '€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ', \
      @cleaner.clean('€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ')
  end

end
