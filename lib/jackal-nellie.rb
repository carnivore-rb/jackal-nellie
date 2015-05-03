require 'jackal'

module Jackal
  module Nellie
    autoload :Processor, 'jackal-nellie/processor'
  end
end

Jackal.service(:nellie)

require 'jackal-nellie/version'
require 'jackal-nellie/formatter'
