$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jackal-nellie/version'
Gem::Specification.new do |s|
  s.name = 'jackal-nellie'
  s.version = Jackal::Nellie::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/carnivore-rb/jackal-nellie'
  s.description = 'Just do stuff'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'jackal', '>= 0.5.0', '< 1.0.0'
  s.add_development_dependency 'carnivore-actor'
  s.add_development_dependency 'jackal-assets'
  s.add_development_dependency 'miasma-local'

  s.files = Dir['lib/**/*'] + %w(jackal-nellie.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
