# encoding: utf-8



# Remove digits from input text
class Xi::ML::Preprocess::Cleaner::DigitCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  def clean(text)
    text.gsub(/[0-9]/, ' ')
  end
end
