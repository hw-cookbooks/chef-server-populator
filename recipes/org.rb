node[:chef_server_populator][:orgs].each do |org, settings|
  user = node[:chef_server_populator][:org_users][org]
  pass = user[:pass] || SecureRandom.base64

  execute 'create populator user' do
    command "chef-server-ctl user-create #{org} #{user[:first]} #{user[:last]} #{user[:email]} #{pass}"
    not_if "chef-server-ctl user-show #{org}"
  end

  execute 'set populator user key' do
    command "chef-server-ctl add-user-key #{org} #{user[:pub_key]} --key-name populator"
    not_if "chef-server-ctl list-user-keys #{org} | grep '^key_name: populator$'"
  end

  execute 'delete default user key' do
    command "chef-server-ctl delete-user-key #{org} default"
    only_if "chef-server-ctl list-user-keys #{org} | grep '^key_name: default$'"
  end

  execute 'create populator org' do
    command "chef-server-ctl org-create #{settings[:name]} #{settings[:full_name]} -a #{org}"
    not_if "chef-server-ctl org-list | grep '^#{settings[:name]}$'"
  end

  execute 'add populator org validator key' do
    command "chef-server-ctl add-client-key #{settings[:name]} #{settings[:name]}-validator #{settings[:validator_pub_key]} --key-name populator"
    not_if "chef-server-ctl list-client-keys #{settings[:name]} #{settings[:name]}-validator | grep '^key_name: populator$'"
  end

  execute 'remove populator org default validator key' do
    command "chef-server-ctl delete-client-key #{settings[:name]} #{settings[:name]}-validator default"
    only_if "chef-server-ctl list-client-keys #{settings[:name]} #{settings[:name]}-validator | grep '^key_name: default$'"
  end
end

node.set['chef-server'][:configuration][:default_orgname] = node[:chef_server_populator][:default_org]

chef_server_ingredient 'chef-server-core' do
  action :reconfigure
  not_if node[:chef_server_populator][:default_org].empty?
end
