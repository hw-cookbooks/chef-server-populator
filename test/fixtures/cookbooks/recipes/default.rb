# This is a test helper recipe that will create public and private
# keys to test populator features.

directory '/tmp/chef-server-populator'

%w(client_key.pem client_key_pub.pem validator.pem validator_pub.pem user_key.pem user_pub.pem).each do |file|
  cookbook_file file do
    path "/tmp/chef-server-populator/#{file}"
  end
end
