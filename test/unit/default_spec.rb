require_relative 'spec_helper'

describe 'chef-server-populator::default' do
  let(:chef_solo_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }
  let(:chef_client_run) { ChefSpec::ServerRunner.new.converge(described_recipe) }

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::solo')
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::client')
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::restore')
  end

  context 'when running under chef-solo' do
    it 'includes solo recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::solo')
      chef_solo_run
    end
  end

  context 'when running under chef-client' do
    it 'includes client recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::client')
      chef_client_run
    end
  end

  context 'when provided values for restore file attribute' do
    it 'includes restore recipe' do
      chef_solo_run.node.normal['chef_server_populator']['restore'][:file] = '/tmp/latest.tgz'
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-server-populator::restore')
      chef_solo_run.converge(described_recipe)
    end
  end
end
