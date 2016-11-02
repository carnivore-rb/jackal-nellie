require 'jackal'

module Jackal
  module Nellie
    module Formatter

      class SlackComment < Jackal::Formatter

        include MessageExtract

        # Source service
        SOURCE = :nellie
        # Destination service
        DESTINATION = :slack

        # Format payload to provide output comment to GitHub
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :nellie, :result))
            msgs = payload.fetch(:data, :slack, :messages, [])
            if(payload.get(:data, :nellie, :result, :complete))
              msgs << Smash.new(
                :description => "#{app_config.fetch(:branding, :name, 'Nellie')} job result:",
                :message => success_message(payload),
                :color => :good
              )
            else
              msgs << Smash.new(
                :description => "#{app_config.fetch(:branding, :name, 'Nellie')} job result:",
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
end
