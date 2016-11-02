require 'jackal-nellie'

module Jackal
  module Nellie
    # Command processor
    class Processor < Callback

      # Default nellie file name
      DEFAULT_SCRIPT_NAME = '.nellie'
      # Default working directory
      DEFAULT_WORKING_DIRECTORY = '/tmp/nellie'

      # Setup callback
      def setup(*_)
        require 'fileutils'
      end

      # @return [String] working directory
      def working_directory
        memoize(:working_directory) do
          wd = config.fetch(:working_directory, DEFAULT_WORKING_DIRECTORY)
          FileUtils.mkdir_p(wd)
          wd
        end
      end

      # @return [String] nellie command file name
      def nellie_script_name
        config.fetch(:script_name, DEFAULT_SCRIPT_NAME)
      end

      # Determine validity of message
      #
      # @param message [Carnivore::Message]
      # @return [Truthy, Falsey]
      def valid?(message)
        super do |payload|
          payload.get(:data, :code_fetcher, :asset) &&
            !payload.get(:data, :nellie, :result)
        end
      end

      # Run nellie!
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          debug "Processing nellie payload!"
          nellie_cwd = fetch_code(payload)
          begin
            unless(payload.get(:data, :nellie, :commands))
              extract_nellie_commands(nellie_cwd, payload)
            end
            if(payload.get(:data, :nellie, :commands))
              execute_commands(nellie_cwd, payload)
            else
              warn "No nellie commands found for execution on message! (#{message})"
            end
          ensure
            debug "Removing nellie job working directory: `#{nellie_cwd}`"
            FileUtils.rm_rf(nellie_cwd)
          end
          job_completed(:nellie, payload, message)
        end
      end

      # Execute commands
      #
      # @param nellie_cwd [String] repository directory
      # @param payload [Smash]
      # @return [TrueClass]
      def execute_commands(nellie_cwd, payload)
        process_environment = payload.fetch(:data, :nellie, :environment, Smash.new).merge(
          Smash.new(
            'NELLIE_GIT_COMMIT_SHA' => payload.get(:data, :code_fetcher, :info, :commit_sha),
            'NELLIE_GIT_REF' => payload.get(:data, :code_fetcher, :info, :reference)
          )
        )
        commands = [payload.get(:data, :nellie, :commands)].flatten.compact
        results = run_commands(commands, process_environment, payload, nellie_cwd)
        payload.set(:data, :nellie, :history, results)
        payload[:data][:nellie].delete(:commands)
        payload[:data][:nellie].delete(:environment)
        if(payload.get(:data, :nellie, :cleanup))
          debug "Cleanup commands detected. Running now."
          cleanup_results = run_commands(payload[:data][:nellie].delete(:cleanup), process_environment, payload, nellie_cwd)
          payload.set(:data, :nellie, :cleanup_history, cleanup_results)
          debug "Cleanup commands have completed."
        end
        unless(payload.get(:data, :nellie, :result, :failed))
          payload.set(:data, :nellie, :result, :complete, true)
          if(payload.get(:data, :nellie, :release_assets))
            set_github_release_assets(payload, nellie_cwd)
          end
        end
        payload.set(:data, :nellie, :status,
          payload.get(:data, :nellie, :result, :complete) ? 'success' : 'error'
        )
        true
      end

      # Populate for pushing github release assets
      #
      # @param payload [Smash]
      # @param nellie_cwd [String] working directory of repo
      # @return [NilClass]
      def set_github_release_assets(payload, nellie_cwd)
        release_assets = Dir.glob(File.join(nellie_cwd, payload.get(:data, :nellie, :release_assets)))
        unless(release_assets.empty?)
          debug "Release assets detected: #{release_assets}"
          release_asset_keys = release_assets.map do |asset|
            asset_key = "nellie/release-assets/#{payload[:id]}/#{File.basename(asset)}"
            asset_store.put(asset_key, File.open(asset, 'rb'))
            asset_key
          end
          if(payload.get(:data, :code_fetcher, :info, :ref).to_s.include?('/tags/'))
            version = payload.get(:data, :code_fetcher, :info, :ref).to_s.sub(/^.*\/tags\//, '')
          else
            version = payload.get(:data, :code_fetcher, :info, :commit_sha).to_s[0,6]
            prerelease = true
          end
          payload.set(:data, :github_kit, :release,
            Smash.new(
              :repository => [
                payload.get(:data, :code_fetcher, :info, :owner),
                payload.get(:data, :code_fetcher, :info, :name)
              ].join('/'),
              :reference => payload.get(:data, :code_fetcher, :info, :commit_sha),
              :tag_name => version,
              :name => [
                payload.get(:data, :code_fetcher, :info, :name),
                version
              ].join('-'),
              :body => "Release - #{payload.get(:data, :code_fetcher, :info, :name)} <#{version}>",
              :prerelease => prerelease,
              :assets => release_asset_keys
            )
          )
          nil
        end
      end

      # Run collection of commands
      #
      # @param commands [Array<String>] commands to execute
      # @param env [Hash] environment variables for process
      # @param payload [Smash]
      # @param process_cwd [String] working directory for process
      # @return [Array<Smash>] command results ({:start_time, :stop_time, :exit_code, :logs, :timed_out})
      def run_commands(commands, env, payload, process_cwd)
        results = []
        stdout = process_manager.create_io_tmp(payload[:id], 'stdout')
        stderr = process_manager.create_io_tmp(payload[:id], 'stderr')
        commands.each do |command|
          process_manager.process(payload[:id], command) do |process|
            info "Running command `#{command}` in `#{process_cwd}`"
            result = Smash.new
            process.io.stdout = stdout
            process.io.stderr = stderr
            process.cwd = process_cwd
            process.environment.replace(env.dup)
            process.leader = true
            result[:start_time] = Time.now.to_i
            process.start
            begin
              process.poll_for_exit(config.fetch(:max_execution_time, 60))
            rescue ChildProcess::TimeoutError
              process.stop
              result[:timed_out] = true
            end
            result[:stop_time] = Time.now.to_i
            result[:exit_code] = process.exit_code
            [stdout, stderr].each do |io|
              key = "nellie/#{File.basename(io.path)}"
              type = io.path.split('-').last
              io.rewind
              asset_store.put(key, io)
              result.set(:logs, type, key)
              io.close
              File.delete(io.path)
            end
            info "Completed command `#{command}` in `#{process_cwd}`. " \
              "Runtime: #{result[:stop_time] - result[:start_time]} seconds"
            results << result
            unless(process.exit_code == 0)
              payload.set(:data, :nellie, :result, :failed, true)
            end
          end
          break if payload.get(:data, :nellie, :result, :failed)
        end
        results
      end

      # Extract nellie commands from repository file
      #
      # @param nellie_cwd [String] path to repository directory
      # @param payload [Smash]
      # @return [TrueClass, FalseClass]
      def extract_nellie_commands(nellie_cwd, payload)
        script_path = File.join(nellie_cwd, nellie_script_name)
        if(File.exists?(script_path))
          begin
            nellie_cmds = MultiJson.load(File.read(script_path)).to_smash #Bogo::Config.new(script_path).data
            debug "Nellie file is structured data. Populating commands into payload. (#{script_path})"
            payload[:data].set(:nellie, :commands, nellie_cmds[:commands])
            payload[:data].set(:nellie, :environment, nellie_cmds.fetch(:environment, {}))
            payload[:data].set(:nellie, :cleanup, Array(nellie_cmds[:cleanup])) if nellie_cmds[:cleanup]
            payload[:data].set(:nellie, :release_assets, nellie_cmds[:release]) if nellie_cmds[:release]
          rescue => e
            debug "Parsing nellie file failed. Assuming direct execution. (#{script_path})"
            payload[:data].set(:nellie, :commands,
              File.executable?(script_path) ? script_path : "/bin/bash #{script_path}"
            )
          end
          true
        else
          debug "Failed to locate nellie command file at: #{script_path}"
          false
        end
      end

      # Fetch code from asset store and unpack for local usage
      #
      # @param payload [Smash]
      # @return [String] directory path
      def fetch_code(payload)
        repository_path = File.join(
          working_directory,
          payload[:id],
          payload.get(:data, :code_fetcher, :asset).sub(/\..*$/, '')
        )
        if(File.directory?(repository_path))
          warn "Existing path detected for repository unpack. Removing! (#{repository_path})"
          FileUtils.rm_rf(repository_path)
        end
        FileUtils.mkdir_p(File.dirname(repository_path))
        code_asset = asset_store.get(payload.get(:data, :code_fetcher, :asset))
        packed_code_asset_path = File.join(working_directory, "code-asset-#{payload[:id]}.zip")
        FileUtils.cp(code_asset.path, packed_code_asset_path)
        packed_code_asset = File.open(packed_code_asset_path, 'rb')
        asset_store.unpack(
          packed_code_asset,
          repository_path
        )
        File.unlink(packed_code_asset_path)
        repository_path
      end

    end
  end
end
