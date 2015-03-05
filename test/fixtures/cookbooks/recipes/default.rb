# This is a test helper recipe that will create public and private
# keys to test populator features.

directory '/tmp/chef-server'

%w(client_key.pem client_key_pub.pem validator.pem validator_pub.pem).each do |file|

  cookbook_file file do
    path "/tmp/chef-server/#{file}"
  end

end
