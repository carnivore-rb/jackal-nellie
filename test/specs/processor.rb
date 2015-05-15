require 'git'
require 'jackal-code-fetcher'
require 'pry'

describe Jackal::CodeFetcher::GitHub do
  # Some of this is a shameful copy-paste job from jackal-code-fetcher
  #  TODO: Look into way to reuse test code from other services
  ASSET_OWNER = 'jackal'
  ASSET_NAME  = 'test-repo'
  # initial commit :)
  COMMIT_SHA  = '2b3aa2cd43223498030daad2732a3e4d3d052cf5'

  before do
    @runner = run_setup(:test)
  end

  after do
    @runner.terminate if @runner && @runner.alive?
    FileUtils.rm_rf(service_config(:code_fetcher, :working_directory))
    FileUtils.rm_rf(@obj_store)
  end

  let(:fetcher_supervisor) { Carnivore::Supervisor.supervisor[:jackal_code_fetcher_input] }
  let(:nellie_supervisor)  { Carnivore::Supervisor.supervisor[:jackal_nellie_input] }

  describe 'jackal code fetcher' do
    it 'fetches repo and stores as local asset' do
      # TODO... cache repo fetching since we're testing nellie, not code-fetcher
      payload = Jackal::Utils.new_payload('fetcher', code_fetcher_config)
      fetcher_supervisor.transmit(payload)

      source_wait(2) { !MessageStore.messages.empty? }
      result = MessageStore.messages.first

      @new_payload = Jackal::Utils.new_payload('nellie', result)
      nellie_supervisor.transmit(@new_payload)

      binding.pry
    end
  end

  private

  def code_fetcher_config
    h = {:code_fetcher => {
           :info => {
             :url   => 'https://github.com/carnivore-rb/jackal-code-fetcher.git',
             :owner => ASSET_OWNER,
             :name  => ASSET_NAME,
             :commit_sha => COMMIT_SHA }}}
  end

  def service_config(name, *keys)
    Carnivore::Config.data.get(*[:jackal, name, :config, *keys])
  end

end
