require 'serverspec'

set :backend, :exec

describe 'chef-server-populator-configurator' do
  describe file('/etc/opscode/pivotal.rb') do
    it { should be_file }
  end

  describe file('/etc/opscode/chef-server.rb') do
    its(:content) { should match /api_fqdn "localhost"/ }
  end
end

describe 'chef-server-org-creation' do
  describe command('chef-server-ctl org-list') do
    its(:stdout) { should match /inception_llc/ }
  end

  describe command('chef-server-ctl list-user-keys populator') do
    its(:stdout) { should match /populator/ }
  end
end

describe 'chef-server-user-creation' do
  describe command('chef-server-ctl user-list') do
    its(:stdout) { should match /pivotal\npopulator/ }
  end

  describe command('chef-server-ctl list-user-keys populator -v') do
    its(:stdout) { should include "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4CeiY3E99UYQFm/xpBJL\nxrmd/zrmCH6yoQva2tXza1+AxOTfSWQcmXWjFMkO1h0w3ElAvieyinRThE9Rl6DE\noGPzJnLzc8AmAMSSdU6gAn8Uto3jQMGk8ByYv+nd1rGMoCl1H29OJuG7g+bkychL\no1sEqQkAn/J+zZ4RHI1E6rXmuEaIRM49j4M0ejh5+zw7YCYiAN/Owz5zrF14P7GL\ni96i5Tek7ndXxAfDOkRiam+I+08rZNspNAVdv0ORHy7sydra/0Y4odC+7f/WrAhE\nHxaPfiUA7/slHmbrZK9/gD7nZf7tpooeaA+nJKVTwWebCVo75APW/KLw7ErYEGyy\n0QIDAQAB\n-----END PUBLIC KEY-----" }
  end

  describe command('sudo chef-server-ctl org-user-add inception_llc populator') do
    its(:stdout) { should match /User populator already associated with organization inception_llc/ }
  end
end

describe 'populator-solo-client-creation' do
  describe command('chef-server-ctl list-client-keys inception_llc test-node -v') do
    its(:stdout) { should include "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4CeiY3E99UYQFm/xpBJL\nxrmd/zrmCH6yoQva2tXza1+AxOTfSWQcmXWjFMkO1h0w3ElAvieyinRThE9Rl6DE\noGPzJnLzc8AmAMSSdU6gAn8Uto3jQMGk8ByYv+nd1rGMoCl1H29OJuG7g+bkychL\no1sEqQkAn/J+zZ4RHI1E6rXmuEaIRM49j4M0ejh5+zw7YCYiAN/Owz5zrF14P7GL\ni96i5Tek7ndXxAfDOkRiam+I+08rZNspNAVdv0ORHy7sydra/0Y4odC+7f/WrAhE\nHxaPfiUA7/slHmbrZK9/gD7nZf7tpooeaA+nJKVTwWebCVo75APW/KLw7ErYEGyy\n0QIDAQAB\n-----END PUBLIC KEY-----" }
  end
end
