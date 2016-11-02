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
          "[#{app_config.fetch(:branding, :name, 'Nellie')}]: Job completed successfully! (#{repo}@#{sha})"
        end

        # Message for failure results
        #
        # @param payload [Smash]
        # @return [String]
        def failure_message(payload)
          msg = ["[#{app_config.fetch(:branding, :name, 'Nellie')}]: Failure encountered:"]
          msg << ''
          failed_history = payload.fetch(:data, :nellie, :history, {}).detect do |i|
            i[:exit_code] != 0
          end
          if(failed_history)
            stdout = asset_store.get(failed_history.get(:logs, :stdout))
            stdout_pos = stdout.size - 1024
            stdout.seek(stdout_pos < 0 ? 0 : stdout_pos)
            stderr = asset_store.get(failed_history.get(:logs, :stderr))
            stderr_pos = stderr.size - 1034
            stderr.seek(stderr_pos < 0 ? 0 : stderr_pos)
            msg << '* STDOUT:' << '' << '```'
            msg << stdout.read
            msg << '```' << ''
            msg << '* STDERR:' << '' << '```'
            msg << stderr.read
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
