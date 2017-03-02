# encoding: utf-8



# The predefined and updatable logger
class Xi::ML::Tools::Logger

  ROOT = 'xi::ml'.freeze

  # Create a new logger
  #
  # @param name [String] the logger's class name
  # @return [Log4r::Logger] return the newly created logger
  def self.create(name='')
    create_root() if Log4r::Logger[ROOT].nil?

    unless Log4r::Logger[name]
      logger = Log4r::Logger.new(name)
      logger.additive = false
      logger.level = Log4r::Logger[ROOT].level
      logger.outputters = Log4r::Logger[ROOT].outputters.clone
    end

    Log4r::Logger[name]
  end

  # Change the logging level of all existing loggers
  #
  # @param level [Integer] the new logger level value
  def self.global_level=(level)
    Log4r::Logger.each do |lname|
      Log4r::Logger[lname].level = level if lname.start_with?(ROOT)
    end
  end

  # Copy the configuration of a reference logger onto all existing loggers
  #
  # @param logger [Log4r::Logger] the reference logger
  def self.copy_config(logger)
    return unless logger.is_a?(Log4r::Logger)
    Log4r::Logger.each do |lname|
      if lname.start_with?(ROOT)
        Log4r::Logger[lname].level = logger.level
        Log4r::Logger[lname].outputters = logger.outputters.clone
      end
    end
  end

  # Create the root logger
  # Every other logger will be using his configuration
  def self.create_root
    return Log4r::Logger[ROOT] if Log4r::Logger[ROOT]

    Log4r::Logger.new(ROOT)
    Log4r::Logger[ROOT].additive = false

    otp = Log4r::StdoutOutputter.new('stdout')
    otp.formatter = Log4r::PatternFormatter.new(
      :date_pattern => '%d-%m-%Y %H:%M:%S',
      :pattern => '%l [%d] [%C]: %M')

    Log4r::Logger[ROOT].outputters << otp
    Log4r::Logger[ROOT]
  end
end
