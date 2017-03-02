# encoding: utf-8



# The class with common logger & timer instance variables
class Xi::ML::Tools::Component
  attr_reader :logger, :timer

  def initialize
    @logger = Xi::ML::Tools::Logger.create(self.class.name.downcase)
    @timer = Xi::ML::Tools::Timer.new()
  end
end
