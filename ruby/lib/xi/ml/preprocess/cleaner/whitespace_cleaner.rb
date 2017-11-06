# encoding: utf-8



# Remove packed whitespaces from input text
class Xi::ML::Preprocess::Cleaner::WhitespaceCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  def clean(text)
    text.split.join(' ')
  end
end
