require 'jackal-assets'
require 'jackal-nellie'
require 'json'
require 'pry'
require 'tmpdir'

describe Jackal::Nellie::Processor do

  before do
    @runner = run_setup(:test)
    @mock_repo_path = Dir.mktmpdir
    @mock_repo_file = "#{@mock_repo_path}/TOUCHED"
    @script_name = service_config(:nellie, :script_name)
    @asset_path = setup_asset
  end

  after do
    @runner.terminate if @runner && @runner.alive?
    FileUtils.rm_rf(@asset_path)
    FileUtils.rm_rf(@mock_repo_path)
  end

  let(:supervisor)  { Carnivore::Supervisor.supervisor[:jackal_nellie_input] }

  describe 'jackal code fetcher' do
    it 'fetches repo and stores as local asset' do
      h = { :code_fetcher => { :asset => @asset_path } }
      payload = Jackal::Utils.new_payload('nellie', h)
      supervisor.transmit(payload)
      source_wait { !MessageStore.messages.empty? }
      result = MessageStore.messages.first

      File.exists?(@mock_repo_file).must_equal true
    end
  end

  private

  def setup_asset
    name = 'nellie.zip'
    cmds = { commands: ["touch #{@mock_repo_file}"] }
    File.write("#{@mock_repo_path}/#{@script_name}", cmds.to_json)
    store = Jackal::Assets::Store.new
    archive = store.pack(@mock_repo_path)
    store.put(name, archive)
    name
  end

  def service_config(name, *keys)
    Carnivore::Config.data.get(*[:jackal, name, :config, *keys])
  end

end
