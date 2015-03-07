conf_dir = node[:chef_server_populator][:base_path]
node.set['chef-server'][:configuration][:default_orgname] = node[:chef_server_populator][:default_org]

node[:chef_server_populator][:orgs].each do |org, settings|
  user = node[:chef_server_populator][:org_users][org]
  pass = user[:pass] || SecureRandom.base64

  execute 'create populator user' do
    command "chef-server-ctl user-create #{org} #{user[:first]} #{user[:last]} #{user[:email]} #{pass}"
    not_if "chef-server-ctl user-show #{org}"
  end

  execute 'set populator user key' do
    command "chef-server-ctl add-user-key #{org} #{conf_dir}/#{user[:pub_key]} --key-name populator"
    not_if "chef-server-ctl list-user-keys #{org} | grep '^key_name: populator$'"
  end

  execute 'delete default user key' do
    command "chef-server-ctl delete-user-key #{org} default"
    only_if "chef-server-ctl list-user-keys #{org} | grep '^key_name: default$'"
  end

  execute 'create populator org' do
    command "chef-server-ctl org-create #{org} #{settings[:full_name]} -a #{org}"
    not_if "chef-server-ctl org-list | grep '^#{settings[:name]}$'"
    if org == node[:chef_server_populator][:default_org]
      notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
    end
  end

  execute 'add populator org validator key' do
    command "chef-server-ctl add-client-key #{settings[:name]} #{settings[:name]}-validator #{conf_dir}/#{settings[:validator_pub_key]} --key-name populator"
    not_if "chef-server-ctl list-client-keys #{settings[:name]} #{settings[:name]}-validator | grep '^key_name: populator$'"
  end

  execute 'remove populator org default validator key' do
    command "chef-server-ctl delete-client-key #{settings[:name]} #{settings[:name]}-validator default"
    only_if "chef-server-ctl list-client-keys #{settings[:name]} #{settings[:name]}-validator | grep '^key_name: default$'"
  end
end
