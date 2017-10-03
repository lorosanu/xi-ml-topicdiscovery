# encoding: utf-8



# Lowercase the input text
# Use 'unicode' library to fix lowercase for accented caracters
class Xi::ML::Preprocess::Cleaner::LowercaseCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  def clean(text)
    Unicode.downcase(text)
  end
end
