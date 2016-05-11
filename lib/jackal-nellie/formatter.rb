module Jackal
  module Nellie
    module Formatter
      module MessageExtract

        # Message for successful results
        #
        # @param payload [Smash]
        # @return [String]
        def success_message(payload)
          repo = [
            payload.get(:data, :code_fetcher, :info, :owner),
            payload.get(:data, :code_fetcher, :info, :name)
          ].join('/')
          sha = payload.get(:data, :code_fetcher, :info, :commit_sha)
          "[nellie]: Job completed successfully! (#{repo}@#{sha})"
        end

        # Message for failure results
        #
        # @param payload [Smash]
        # @return [String]
        def failure_message(payload)
          msg = ['[nellie]: Failure encountered:']
          msg << ''
          failed_history = payload.fetch(:data, :nellie, :history, {}).detect do |i|
            i[:exit_code] != 0
          end
          if(failed_history)
            msg << '* STDOUT:' << '' << '```'
            msg << asset_store.get(failed_history.get(:logs, :stdout)).read
            msg << '```' << ''
            msg << '* STDERR:' << '' << '```'
            msg << asset_store.get(failed_history.get(:logs, :stderr)).read
            msg << '```'
          else
            msg << '```' << 'Failed to locate logs' << '```'
          end
          msg.join("\n")
        end

      end
    end
  end
end

require 'jackal-nellie/formatter/github_commit_status'
require 'jackal-nellie/formatter/github_commit_comment'
require 'jackal-nellie/formatter/slack_comment'
