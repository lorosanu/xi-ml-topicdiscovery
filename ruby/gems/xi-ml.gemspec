# coding: utf-8


lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'time'
require 'xi/ml/version'

Gem::Specification.new do |spec|
  spec.name             = 'xi-ml'
  spec.version          = Xi::ML::VERSION
  spec.date             = Time.now.to_date.strftime('%Y-%m-%d')
  spec.authors          = %w{Luiza\ Orosanu}
  spec.email            = %w{luiza.orosanu@xilopix.com}
  spec.summary          = %q{Xi ML lib}
  spec.description      = %q{Xilopix Machine Learning library}

  spec.add_runtime_dependency 'xi-ml-topicdiscovery', "= #{Xi::ML::VERSION}"

  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'xi-rake', '~> 0.1', '>= 0.1.0'

  spec.required_ruby_version = '>= 1.9.1'
end
