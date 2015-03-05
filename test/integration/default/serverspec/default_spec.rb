require_relative './spec_helper'

describe 'chef-server-populator-configurator' do

  describe file('/etc/opscode/chef-server.rb') do
    its(:content) { should match /api_fqdn "localhost"/ }
    its(:content) { should match /default_orgname "populator"/ }
  end

  describe command('chef-server-ctl org-list') do
    its(:stdout) { should match /inception_llc/ }
  end

  describe command('chef-server-ctl user-list') do
    its(:stdout) { should match /pivotal\npopulator/ }
  end

  describe command('chef-server-ctl list-client-keys populator populator') do
    its(:stdout) { should match /populator/ }
  end
  
end
