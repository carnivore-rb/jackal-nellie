require 'jackal'

module Jackal
  module Nellie
    module Formatter

      class SlackComment < Jackal::Formatter

        # Source service
        SOURCE = :nellie
        # Destination service
        DESTINATION = :slack

        # Format payload to provide output comment to GitHub
        #
        # @param payload [Smash]
        def format(payload)
          msgs = payload.fetch(:data, :slack, :messages, [])
          if(payload.get(:data, :nellie, :result, :success))
            msgs << Smash.new(
              :description => 'Nellie job result:',
              :message => success_message(payload),
              :color => :good
            )
          else
            msgs << Smash.new(
              :description => 'Nellie job result:',
              :message => failure_message(payload),
              :color => :bad
            )
          end
          payload.set(:data, :slack, :messages, msgs)
        end

      end
    end
  end
end
