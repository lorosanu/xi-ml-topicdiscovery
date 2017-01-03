# encoding: utf-8


require 'pp'
require 'uri'               # URL parser
require 'time'
require 'json'
require 'yaml'
require 'digest'            # SHA1 conversion
require 'fileutils'         # create path
require 'unicode_utils'     # lib to lowercase accents
require 'log4r'
require 'elasticsearch'
require 'socket'
require 'timeout'

module Xi
  module ML
  end
end

require 'xi/ml/error'
require 'xi/ml/tools'

module Xi::ML
  @logger = Xi::ML::Tools::Logger.create_root()
  def self.logger
    @logger
  end
end

require 'xi/ml/corpus'
require 'xi/ml/extract'
require 'xi/ml/build'

require 'xi/ml/preprocess'
require 'xi/ml/transform'
require 'xi/ml/classify'
