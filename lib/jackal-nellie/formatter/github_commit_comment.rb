require 'jackal'

module Jackal
  module Nellie
    module Formatter

      class GithubCommitComment < Jackal::Formatter

        include MessageExtract

        # Source service
        SOURCE = :nellie
        # Destination service
        DESTINATION = :github_kit

        # Format payload to provide output comment to GitHub
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :nellie, :result))
            payload.set(:data, :github_kit, :commit_comment,
              Smash.new(
                :repository => [
                  payload.get(:data, :code_fetcher, :info, :owner),
                  payload.get(:data, :code_fetcher, :info, :name)
                ].join('/'),
                :reference => payload.get(:data, :code_fetcher, :info, :commit_sha)
              )
            )
            if(payload.get(:data, :nellie, :result, :complete))
              payload.set(:data, :github_kit, :commit_comment, :message, success_message(payload))
            else
              payload.set(:data, :github_kit, :commit_comment, :message, failure_message(payload))
            end
          end
        end

      end
    end
  end
end
