require 'jackal'

module Jackal
  module Nellie
    autoload :Processor, 'jackal-nellie/processor'
  end
end

Jackal.service(
  :nellie,
  :description => 'Run commands',
  :configuration => {
    :working_directory => {
      :type => :string,
      :public => false,
      :description => 'Host working directory'
    },
    :script_name => {
      :type => :string,
      :description => 'Relative path of nellie file'
    },
    :max_execution_time => {
      :type => :number,
      :public => false,
      :description => 'Maximum number of seconds each command is allowed to run'
    }
  }
)

require 'jackal-nellie/version'
require 'jackal-nellie/formatter'
