require_relative 'spec_helper'

describe 'chef-server-populator::org' do

  let(:default_org) { 'nasa' }

  let(:test_org) {
    Mash.new(
      :org_name => 'endurance',
      :full_name => 'Endurance Shuttle Mission',
      :validator_pub_key => 'validation_pub.pem'
    )
  }

  let(:test_org_user) {
    Mash.new(
      :name => 'murph',
      :first => 'Murphy',
      :last => 'Cooper',
      :email => 'murph@nasa.gov'
    )
  }

  let(:list_user_keys_cmd) {
    "chef-server-ctl list-user-keys #{test_org_user[:name]}"
  }

  let(:list_validator_keys_cmd) {
    "chef-server-ctl list-client-keys #{test_org[:org_name]} #{test_org[:org_name]}-validator"
  }

  let(:chef_run) {
    ChefSpec::ServerRunner.new do |node, _server|
      node.set[:chef_server_populator][:solo_org] = test_org
      node.set[:chef_server_populator][:solo_org_user] = test_org_user
      node.set[:chef_server_populator][:default_org] = default_org
    end.converge(described_recipe)
  }

  let(:execute_create_populator_org) {
    chef_run.execute('create populator org')
  }

  before do
    stub_command("chef-server-ctl user-show #{test_org_user[:name]}").and_return(false)
    stub_command("#{list_user_keys_cmd} | grep 'name: populator$'").and_return(false)
    stub_command("#{list_user_keys_cmd} | grep 'name: default$'").and_return(false)
    stub_command("chef-server-ctl org-list | grep '^#{test_org[:org_name]}$'").and_return(false)
    stub_command("#{list_validator_keys_cmd} | grep 'name: populator$'").and_return(false)
    stub_command("#{list_validator_keys_cmd} | grep 'name: default$'").and_return(false)
    stub_command("chef-server-ctl list-client-keys #{test_org[:org_name]} #{test_org[:org_name]}-validator | grep 'name: populator$'").and_return(false)
        stub_command("chef-server-ctl list-client-keys #{test_org[:org_name]} #{test_org[:org_name]}-validator | grep 'name: default$'").and_return(true)
  end

  it 'overrides the chef-server default_orgname' do
    expect(chef_run.node['chef-server'][:configuration][:default_orgname]).to eq(default_org)
  end


  it 'creates the populator user' do
    expect(chef_run).to run_execute('create populator user')
  end

  context 'when the populator user has a default key' do
    it 'deletes the populator user\'s default key' do
      stub_command("#{list_user_keys_cmd} | grep 'name: default$'").and_return(true)
      chef_run.converge(described_recipe)
      expect(chef_run).to run_execute('delete default user key')
    end
  end

  context 'when the populator user does not have a default key' do
    it 'does not delete the populator user\'s default key' do
      expect(chef_run).to_not run_execute('delete default user key')
    end
  end

  context 'when the populator org does not exist' do
    it 'creates the populator organization' do
      expect(chef_run).to run_execute('create populator org')
    end

    context 'when the populator org is also the default org' do
      it 'notifies chef-server to reconfigure immediately' do
        chef_run.node.set[:chef_server_populator][:default_org] = test_org[:org_name]
        chef_run.converge(described_recipe)
        expect(execute_create_populator_org).to notify('chef_server_ingredient[chef-server-core]').to(:reconfigure).immediately
      end
    end
  end

  context 'when the populator org does not have a "populator" validator key' do
    it 'adds a validator key for the populator org' do
      stub_command("#{list_validator_keys_cmd} | grep 'name: populator$'").and_return(false)
      expect(chef_run).to run_execute('add populator org validator key')
    end
  end

  context 'when the populator org has a "populator" validator key' do
    it 'does not add a validator key for the populator org' do
      stub_command("#{list_validator_keys_cmd} | grep 'name: populator$'").and_return(true)
      chef_run.converge(described_recipe)
      expect(chef_run).to_not run_execute('add populator org validator key')
    end
  end

  context 'when the populator org has a default validator key' do
    it 'removes the populator default validator key' do
      stub_command("#{list_validator_keys_cmd} | grep 'name: default$'").and_return(true)
      chef_run.converge(described_recipe)
      expect(chef_run).to run_execute('remove populator org default validator key')
    end
  end
end
