require 'jackal'

module Jackal
  module Nellie
    module Formatter

      class GithubCommitStatus < Jackal::Formatter

        include MessageExtract

        # Source service
        SOURCE = :nellie
        # Destination service
        DESTINATION = :github_kit

        # Format payload to provide output status to GitHub
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :nellie, :result))
            payload.set(:data, :github_kit, :status,
              Smash.new(
                :repository => [
                  payload.get(:data, :code_fetcher, :info, :owner),
                  payload.get(:data, :code_fetcher, :info, :name)
                ].join('/'),
                :reference => payload.get(:data, :code_fetcher, :info, :commit_sha),
                :state => payload.get(:data, :nellie, :result, :failed) ? 'failure' : 'success',
                :extras => {
                  :context => 'nellie',
                  :description => payload.get(:data, :nellie, :result, :failed) ?
                    failure_message(payload) :
                    success_message(payload)
                }
              )
            )
          end
        end

      end
    end
  end
end
