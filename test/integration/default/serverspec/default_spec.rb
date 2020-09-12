require_relative './spec_helper'

describe 'chef-server-default-org' do
  describe file('/etc/opscode/chef-server.rb') do
    its(:content) { should match /default_orgname\("inception_llc"\)/ }
  end
end

describe 'chef-server-populator-cookbook-upload' do
  describe command('knife cookbook list -c /etc/opscode/pivotal.rb') do
    its(:stdout) { should match /chef-server-populator/ }
  end
end
