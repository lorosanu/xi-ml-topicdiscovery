# coding: utf-8


lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'time'
require 'xi/ml/version'

Gem::Specification.new do |spec|
  spec.name             = 'xi-ml-topicdiscovery'
  spec.version          = Xi::ML::VERSION
  spec.date             = Time.now.to_date.strftime('%Y-%m-%d')
  spec.authors          = %w{Luiza\ Orosanu}
  spec.email            = %w{luiza.orosanu@xilopix.com}
  spec.summary          = %q{Xi ML Topic Discovery lib}
  spec.description      = %q{Xilopix Machine Learning for Topic Discovery}

  spec.files            = `git ls-files -z lib/`.split("\x0")
  spec.extra_rdoc_files = `git ls-files -z conf/`.split("\x0") + %w{README}

  spec.add_runtime_dependency 'json', '~> 1.8', '>= 1.8.1'
  spec.add_runtime_dependency 'log4r', '~> 1.1', '>= 1.1.10'
  spec.add_runtime_dependency 'unicode_utils', '~> 1.4', '>= 1.4.0'
  spec.add_runtime_dependency 'elasticsearch', '~> 1.1', '>= 1.1.0'
  # FIXME: to be added when NLP will be needed
  # spec.add_runtime_dependency 'xi-nlp', '~> 2.0', '>= 2.0.1'
end
