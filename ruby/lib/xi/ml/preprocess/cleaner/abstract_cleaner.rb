# encoding: utf-8



# The 'abstract' class used as template for extending cleaning classes
class Xi::ML::Preprocess::Cleaner::AbstractCleaner

  # @return the list of classes extending this class
  def self.descendants
    ObjectSpace.each_object(Class).select {|desc_class| desc_class < self }
  end

  # @return the list of classes names extending this class
  def self.descendants_names
    self.descendants.map {|desc_class| desc_class.to_s }
  end

  # force child classes to (re)define this method
  def clean(_)
    raise Xi::ML::Error::ConfigError, \
      "Method 'clean' not defined in #{self.class} class"
  end
end
