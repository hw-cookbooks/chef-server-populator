org = node[:chef_server_populator][:populator_org]
user = node[:chef_server_populator][:populator_user]
pass = user[:pass] || SecureRandom.base64

execute 'create populator user' do
  command "chef-server-ctl user-create #{user[:name]} #{user[:first]} #{user[:last]} #{user[:email]} #{pass}"
  not_if "chef-server-ctl show-user #{user[:name]} | grep '^username: #{user[:name]}$'"
end

execute 'set populator user key' do
  command "chef-server-ctl add-user-key #{user[:name]} #{user[:pub_key]} --key-name populator"
  not_if "chef-server-ctl list-user-keys #{user[:name]} | grep '^key_name: populator$'"
end

execute 'delete default user key' do
  command "chef-server-ctl delete-user-key #{user[:name]} default"
  only_if "chef-server-ctl list-user-keys #{user[:name]} | grep '^key_name: default$'"
end

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:name]} #{org[:full_name]} -a #{user[:name]}"
  not_if "chef-server-ctl org-list | grep '^#{org[:name]}$'"
end

execute 'add populator org validator key' do
  command "chef-server-ctl add-client-key #{org[:name]} #{org[:name]}-validator #{org[:validator_pub_key]} --key-name populator"
  not_if "chef-server-ctl list-client-keys #{org[:name]} #{org[:name]}-validator | grep '^key_name: populator$'"
end

execute 'remove populator org default validator key' do
  command "chef-server-ctl delete-client-key #{org[:name]} #{org[:name]}-validator default"
  only_if "chef-server-ctl list-client-keys #{org[:name]} #{org[:name]}-validator | grep '^key_name: default$'"
end

node.set['chef-server'][:configuration][:default_orgname] = node[:chef_server_populator][:populator_org][:name]

chef_server_ingredient 'chef-server-core' do
  action :reconfigure
end
