require_relative './spec_helper'

describe 'Create user with correct fields' do
  describe command('chef-server-ctl user-show test-user') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Test User' }
    its(:stdout) { should contain 'testuser@example.com' }
  end
end
describe 'NO OPs' do
  describe command('chef-server-ctl user-list') do
    its(:stdout) { should_not match /keyless-user/ }
    its(:stdout) { should_not match /non-chef-user/ }
  end
end
