# encoding: utf-8



# Remove words with more than 30 letters
# Remove words having at least 3 same consecutive letters
class Xi::ML::Preprocess::Cleaner::BadwordCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  MAXSIZE = 30

  def initialize(*)
  end

  def clean(text)
    nwords = []

    text.split.each do |word|
      if word.size < MAXSIZE && !(Unicode.downcase(word) =~ /(\p{Ll})\1\1/)
        nwords << word
      end
    end

    nwords.join(' ')
  end
end
