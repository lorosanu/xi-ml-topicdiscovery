# encoding: utf-8



# Remove punctuation marks from input text
class Xi::ML::Preprocess::Cleaner::PunctCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  # Remove all non alphanumeric characters
  # Add a space after apostrophe (ex: n'est => n' est)
  def clean(text)
    ctext = text.gsub(/[^\p{Latin}0-9']/, ' ')
    ctext.gsub!("'", "' ")
    ctext
  end
end
