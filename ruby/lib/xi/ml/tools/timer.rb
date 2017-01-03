# encoding: utf-8



# The predefined timer for executions
class Xi::ML::Tools::Timer
  attr_reader :logger, :start_time, :elapsed_time

  def initialize
    @logger = Xi::ML::Tools::Logger.create(self.class.name.downcase)
    @start_time = Time.now
    @elapsed_time = 0
  end

  def start_timer
    @start_time = Time.now
  end

  def stop_timer(msg = '')
    @elapsed_time = '%.3f' % (Time.now - @start_time)
    @logger.info("#{msg} in #{@elapsed_time} seconds")
  end
end
