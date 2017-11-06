# encoding: utf-8


module Xi::ML::Preprocess::Cleaner
end

require 'xi/ml/preprocess/cleaner/abstract_cleaner'
require 'xi/ml/preprocess/cleaner/digit_cleaner'
require 'xi/ml/preprocess/cleaner/lowercase_cleaner'
require 'xi/ml/preprocess/cleaner/punct_cleaner'
require 'xi/ml/preprocess/cleaner/whitespace_cleaner'
require 'xi/ml/preprocess/cleaner/upcase_cleaner'
require 'xi/ml/preprocess/cleaner/badword_cleaner'

# Do not load the NLP cleaner if NLP is not installed
begin
  require 'xi/ml/preprocess/cleaner/nlp_cleaner'
rescue LoadError
  nil
end
