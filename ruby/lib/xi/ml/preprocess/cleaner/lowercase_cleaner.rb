# encoding: utf-8



# Lowercase the input text
# Use 'unicode_utils' library to fix lowercase for accented caracters
class Xi::ML::Preprocess::Cleaner::LowercaseCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  def clean(text)
    UnicodeUtils.downcase(text)
  end
end
