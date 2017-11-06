# encoding: utf-8



# Fix baddly formated words with unnecessary uppercase letters
# Use 'unicode' library to fix lowercase for accented caracters
class Xi::ML::Preprocess::Cleaner::UpcaseCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  def clean(text)
    nwords = []

    text.split.each do |word|
      if word != Unicode.upcase(word)
        # check for badly formatted words (ex: JOURNEEJeudi, journeeJEUDI)
        if word =~ /[\p{Lu}]{2}/
          word = word.gsub(/(?<=\p{Lu})(\p{Lu}+)(?=\p{Lu}|$)/)\
            {|match| Unicode.downcase(match) }
        end

        # check for camel case words (ex: JourneeJeudi)
        word = word.split(/(?=[\p{Lu}])/).join(' ') if word =~ /[\p{Lu}]/
      end

      nwords << word
    end

    nwords.join(' ')
  end
end
