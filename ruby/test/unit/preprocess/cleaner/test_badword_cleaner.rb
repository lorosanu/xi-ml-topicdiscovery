# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class BadwordCleanerTest < Minitest::Unit::TestCase
  def setup
    @cleaner = Xi::ML::Preprocess::Cleaner::BadwordCleaner.new()
  end

  def test_letters
    assert_equal 'Hello World', @cleaner.clean('Hello World')
  end

  def test_digits
    assert_equal '12 334 423523 543534', @cleaner.clean('12 334 423523 543534')
  end

  def test_letters_digits
    assert_equal 'Asfsfnssfs Sg9 78 78 T', \
      @cleaner.clean('Asfsfnssfs bbbasd sdasssdaf bsnadaaa Sg9 78 78 T')
  end

  def test_accents
    assert_equal 'Après Ça', @cleaner.clean('Après Ça ééécole')
  end

  def test_apostrophe
    assert_equal 'Quoi', @cleaner.clean("C'ESTTT Quoi")
  end

  def test_long_words
    assert_equal '!', \
      @cleaner.clean('Bonjooooooooooooouuuuuuuuuuuur !')
  end

  def test_punctuation
    assert_equal "Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?", \
      @cleaner.clean("Bonjour !@#$%^&*()-=_+|;:\"`,.<>[]{}~\/ Comment vas tu?")
  end

  def test_symbols
    assert_equal '€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ', \
      @cleaner.clean('€ ≈ ≃ ≅ ~ ♎ ± √ ∑ ⋯ … ∞ ↔ ⇔ σ')
  end

end
