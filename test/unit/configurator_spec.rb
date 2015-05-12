require 'spec_helper'

describe 'chef-server-populator::configurator' do

  let(:fqdn) { 'amazing-chef-server.example.com' }
  let(:endpoint) { 'amazing-chef-816064413.us-west-1.elb.amazonaws.com' }

  let(:chef_run) {
    ChefSpec::SoloRunner.new do |node|
      node.automatic[:fqdn] = fqdn
      node.set[:chef_server_populator][:chef_server][:version] = '12.0.5'
      node.set[:chef_server_populator][:chef_server][:foo] = 'bar'
    end.converge(described_recipe)
  }

  it 'overrides chef-server attributes with those from the chef_server_populator.chef_server hash' do
    expect(chef_run.node['chef-server'][:foo]).to eq('bar')
  end

  context 'with a specified endpoint' do
    before do
      chef_run.node.set[:chef_server_populator][:endpoint] = endpoint
      chef_run.converge(described_recipe)
    end

    it 'overrides the values of a number of chef-server attributes with the specified endpoint' do
      expect(chef_run.node['chef-server'][:configuration][:nginx][:server_name]).to eq(endpoint)
      expect(chef_run.node['chef-server'][:configuration][:bookshelf][:vip]).to eq(endpoint)
      expect(chef_run.node['chef-server'][:configuration][:lb][:api_fqdn]).to eq(endpoint)
      expect(chef_run.node['chef-server'][:configuration][:lb][:web_ui_fqdn]).to eq(endpoint)

      expect(chef_run.node['chef-server'][:configuration][:nginx][:url]).to eq("https://#{endpoint}")
      expect(chef_run.node['chef-server'][:configuration][:bookshelf][:url]).to eq("https://#{endpoint}")
    end
  end

  context 'without a specified endpoint' do
    it 'overrides the values of a number of chef-server attributes with the node\'s fqdn' do
      expect(chef_run.node['chef-server'][:configuration][:nginx][:server_name]).to eq(fqdn)
      expect(chef_run.node['chef-server'][:configuration][:bookshelf][:vip]).to eq(fqdn)
      expect(chef_run.node['chef-server'][:configuration][:lb][:api_fqdn]).to eq(fqdn)
      expect(chef_run.node['chef-server'][:configuration][:lb][:web_ui_fqdn]).to eq(fqdn)

      expect(chef_run.node['chef-server'][:configuration][:nginx][:url]).to eq("https://#{fqdn}")
      expect(chef_run.node['chef-server'][:configuration][:bookshelf][:url]).to eq("https://#{fqdn}")
    end
  end

  it 'includes chef-server recipe' do
    expect(chef_run).to include_recipe('chef-server')
  end
end
