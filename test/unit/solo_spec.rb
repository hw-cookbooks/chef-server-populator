require_relative 'spec_helper'

describe 'chef-server-populator::solo' do
  let(:server_org) { 'nasa' }
  let(:default_org) { 'endurance' }
  let(:base_path) { '/tmp/populator' }

  let(:test_org) do
    Mash.new(
      :org_name => 'endurance',
      :full_name => 'Endurance Shuttle Mission',
      :validator_pub_key => 'validation_pub.pem'
    )
  end

  let(:test_org_user) do
    Mash.new(
      :name => 'murph',
      :first => 'Murphy',
      :last => 'Cooper',
      :email => 'murph@nasa.gov'
    )
  end

  let(:list_user_keys_cmd) { "chef-server-ctl list-user-keys #{test_org_user[:name]}" }

  let(:list_validator_keys_cmd) { "chef-server-ctl list-client-keys #{test_org[:org_name]} #{test_org[:org_name]}-validator" }

  let(:list_client_keys_cmd) { "chef-server-ctl list-client-keys #{server_org} #{test_org_user[:name]}" }

  let(:list_validator_client_keys) { "chef-server-ctl list-client-keys #{test_org[:org_name]} #{test_org[:org_name]}-validator" }

  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set[:chef_server_populator][:server_org] = server_org
      node.set[:chef_server_populator][:default_org] = default_org
      node.set[:chef_server_populator][:solo_org] = test_org
      node.set[:chef_server_populator][:solo_org_user] = test_org_user
    end.converge(described_recipe)
  end

  let(:execute_create_populator_org) { chef_run.execute('create populator org') }

  before do
    stub_command("chef-server-ctl user-show #{test_org_user[:name]}").and_return(false)
    stub_command("#{list_user_keys_cmd} | grep 'name: #{test_org_user[:name]}$'").and_return(false)
    stub_command("#{list_user_keys_cmd} | grep 'name: default$'").and_return(false)
    stub_command("#{list_user_keys_cmd} | grep 'name: populator$'").and_return(false)
    stub_command("chef-server-ctl org-list | grep '^#{test_org[:org_name]}$'").and_return(false)
    stub_command("#{list_validator_client_keys} | grep 'name: populator$'").and_return(false)
    stub_command("#{list_validator_client_keys} | grep 'name: default$'").and_return(true)
    stub_command("#{list_client_keys_cmd} | grep 'name: default$'").and_return(false)
    stub_command("/usr/bin/knife client list -s https://127.0.0.1/organizations/#{server_org} -c /etc/opscode/pivotal.rb| tr -d ' ' | grep '^#{test_org_user[:name]}$'").and_return(false)
    stub_command("#{list_client_keys_cmd} | grep 'name: populator$'").and_return(false)
  end

  it 'includes the configurator recipe' do
    expect(chef_run).to include_recipe('chef-server-populator::configurator')
  end

  context 'without a default_org specified' do

    before do
      chef_run.node.set[:chef_server_populator][:default_org] = nil
      chef_run.converge(described_recipe)
    end

    it 'assigns the server_org as the default org' do
      expect(chef_run.node[:chef_server_populator][:default_org]).to eq(server_org)
    end

  end

  it 'includes the org recipe' do
    expect(chef_run).to include_recipe('chef-server-populator::org')
  end

  # The following tests cover behavior in the 'org' recipe. They are included in this spec
  # because:
  #
  # a) placing these tests in a seperate spec made us unable to see the chef_server_ingredient
  #    resource inserted by including the configurator recipe in the 'solo' recipe,
  #    making it difficult to ensure a required notification to such a resource is triggered.
  #
  # b) the only intended use for the 'org' recipe is to run in sequence with the rest of the 'solo'
  # recipe described here.
  #

  it 'overrides the chef-server default_orgname' do
    expect(chef_run.node['chef-server'][:configuration][:default_orgname]).to eq(default_org)
  end

  it 'creates the populator user' do
    expect(chef_run).to run_execute('create populator user')
  end

  context 'when the populator user has a default key' do
    before do
      stub_command("#{list_user_keys_cmd} | grep 'name: default$'").and_return(true)
    end

    it 'deletes the populator user\'s default key' do
      expect(chef_run).to run_execute('delete default user key')
    end
  end

  context 'when the populator user does not have a default key' do
    before do
      stub_command("#{list_user_keys_cmd} | grep 'name: default$'").and_return(false)
    end

    it 'does not delete the populator user\'s default key' do
      expect(chef_run).to_not run_execute('delete default user key')
    end
  end

  context 'when the populator org does not exist' do
    it 'creates the populator organization' do
      expect(chef_run).to run_execute('create populator org')
    end

    context 'when the populator org is also the default org' do
      before do
        chef_run.node.set[:chef_server_populator][:default_org] = test_org[:org_name]
        chef_run.converge(described_recipe)
      end

      it 'notifies chef-server to reconfigure immediately' do
        expect(execute_create_populator_org).to notify('chef_server_ingredient[chef-server-core]').to(:reconfigure).immediately
      end
    end
  end

  context 'when the populator org does not have a "populator" validator key' do
    before do
      stub_command("#{list_validator_keys_cmd} | grep 'name: populator$'").and_return(false)
    end

    it 'adds a validator key for the populator org' do
      expect(chef_run).to run_execute('add populator org validator key')
    end
  end

  context 'when the populator org has a "populator" validator key' do
    before do
      stub_command("#{list_validator_keys_cmd} | grep 'name: populator$'").and_return(true)
    end

    it 'does not add a validator key for the populator org' do
      expect(chef_run).to_not run_execute('add populator org validator key')
    end
  end

  context 'when the populator org has a default validator key' do
    before do
      stub_command("#{list_validator_keys_cmd} | grep 'name: default$'").and_return(true)
    end

    it 'removes the populator default validator key' do
      expect(chef_run).to run_execute('remove populator org default validator key')
    end
  end

  # End tests covering 'org' recipe

  context 'for each client defined in attributes' do

    before do
      chef_run.node.set[:chef_server_populator][:clients] = {
        test_org_user[:name] => "-----BEGIN PUBLIC KEY-----\n-----END PUBLIC KEY-----\n"
      }

      stub_command("#{list_client_keys_cmd} | grep 'name: default$'").and_return(false)
      chef_run.converge(described_recipe)
    end

    it 'creates a client for each client defined in attributes' do
      expect(chef_run).to run_execute("create client: #{test_org_user[:name]}")
    end

    context 'when the client has a default key on the server' do

      before do
        stub_command("#{list_client_keys_cmd} | grep 'name: default$'").and_return(true)
        chef_run.converge(described_recipe)
      end

      it 'removes the client\'s default public key' do
        expect(chef_run).to run_execute("remove default public key for #{test_org_user[:name]}")
      end

    end

    it 'sets the client\'s public key' do
      expect(chef_run).to run_execute("set public key for: #{test_org_user[:name]}")
    end
  end

  it 'uploads the chef-server-populator cookbook to the new Chef server' do
    expect(chef_run).to run_execute('install chef-server-populator cookbook').with(
      :retries => 5
    )
  end

end
