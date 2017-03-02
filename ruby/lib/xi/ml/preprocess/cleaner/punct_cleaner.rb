# encoding: utf-8



# Remove punctuation marks from input text
class Xi::ML::Preprocess::Cleaner::PunctCleaner \
  < Xi::ML::Preprocess::Cleaner::AbstractCleaner

  def initialize(*)
  end

  # Remove punctuation
  # Add a space after apostrophe (ex: n'est => n' est)
  def clean(text)
    # /[!@#$%^&*()\-=_+|;:"`,.<>?\[\]{}~\/]/
    punctuation = %r{[!@#$%^&*()\-=_+|;:"`,.<>?\[\]{}~\/]}
    text.gsub!(punctuation, ' ')
    text.gsub("'", "' ")
  end

end
