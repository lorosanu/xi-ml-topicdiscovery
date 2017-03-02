# encoding: utf-8



# The class meant to execute useful file commands
class Xi::ML::Tools::Utils

  # static method to recover file name with extension
  def self.filename(input)
    return '' if input.nil? || File.basename(input).nil?
    File.basename(input)
  end

  # static method to recover file basename
  def self.basename(input)
    return '' if input.nil?
    File.basename(input, File.extname(input))
  end

  # static method to recover file dirname
  def self.dirname(input)
    return '' if input.nil?
    File.dirname(input)
  end

  # static method to recover file extension
  def self.extname(input)
    return '' if input.nil?
    File.extname(input)
  end

  # static method to recover path without extension
  def self.path_without_ext(input)
    return '' if input.nil?
    File.join(self.dirname(input), self.basename(input))
  end

  # static method to check right file extension
  def self.check_right_extension!(input, ext)
    raise Xi::ML::Error::ConfigError, 'Empty file name' \
      if input.nil? || input == ''

    raise Xi::ML::Error::ConfigError, \
      "File '#{input}' does not have the '#{ext}' extension" \
      unless File.extname(input) == ext
  end

  # static method to check file existance
  def self.check_file_readable!(input)
    raise Xi::ML::Error::ConfigError, 'Empty file name' \
      if input.nil? || input == ''

    raise Xi::ML::Error::ConfigError, \
      "File '#{input}' is missing or not readable" \
      unless File.readable?(input)
  end

  # static method to check folder existance
  def self.check_folder_readable!(input)
    raise Xi::ML::Error::ConfigError, 'Empty folder name' \
      if input.nil? || input == ''

    raise Xi::ML::Error::ConfigError, \
      "Folder '#{input}' is missing or not readable" \
      unless File.directory?(input)
  end

  # static method to create folder path
  def self.create_folder(output)
    return if output.nil? || output == ''
    FileUtils.mkdir_p(output) unless File.directory?(output)
  end

  # static method to create file path
  def self.create_path(output)
    return if output.nil? || output == ''
    self.create_folder(File.dirname(output))
  end

end
