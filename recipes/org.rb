include_recipe 'chef-server-populator::configurator'
include_recipe 'chef-server'

conf_dir = node['chef_server_populator']['base_path']

org = node['chef_server_populator']['solo_org']
user = node['chef_server_populator']['solo_org_user']
pass = user[:pass] || SecureRandom.urlsafe_base64(23).gsub(/^\-*/, '')

execute 'create populator user' do
  command "chef-server-ctl user-create #{user[:name]} #{user[:first]} #{user[:last]} #{user[:email]} #{pass}"
  not_if "chef-server-ctl user-show #{user[:name]}"
end

execute 'set populator user key' do
  if node['chef-server']['version'].to_f >= 12.1 || node['chef-server']['version'].to_f == 0.0
    command "chef-server-ctl add-user-key #{user[:name]} --public-key-path #{conf_dir}/#{user[:pub_key]} --key-name populator"
  else
    command "chef-server-ctl add-user-key #{user[:name]} #{conf_dir}/#{user[:pub_key]} --key-name populator"
  end
  not_if "chef-server-ctl list-user-keys #{user[:name]} | grep 'name: populator$'"
end

execute 'delete default user key' do
  command "chef-server-ctl delete-user-key #{user[:name]} default"
  only_if "chef-server-ctl list-user-keys #{user[:name]} | grep 'name: default$'"
end

execute 'reconfigure for populator org create' do
  command 'chef-server-ctl reconfigure'
  action :nothing
end

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:org_name]} #{org[:full_name]} -a #{user[:name]}"
  not_if "chef-server-ctl org-list | grep '^#{org[:org_name]}$'"
  if org[:org_name] == node['chef_server_populator']['default_org']
    notifies :run, 'execute[reconfigure for populator org create]', :immediately
  end
end

execute 'add populator org validator key' do
  if node['chef-server']['version'].to_f >= 12.1 || node['chef-server']['version'].to_f == 0.0
    command "chef-server-ctl add-client-key #{org[:org_name]} #{org[:org_name]}-validator --public-key-path #{conf_dir}/#{org[:validator_pub_key]} --key-name populator"
  else
    command "chef-server-ctl add-client-key #{org[:org_name]} #{org[:org_name]}-validator #{conf_dir}/#{org[:validator_pub_key]} --key-name populator"
  end
  not_if "chef-server-ctl list-client-keys #{org[:org_name]} #{org[:org_name]}-validator | grep 'name: populator$'"
end

execute 'remove populator org default validator key' do
  command "chef-server-ctl delete-client-key #{org[:org_name]} #{org[:org_name]}-validator default"
  only_if "chef-server-ctl list-client-keys #{org[:org_name]} #{org[:org_name]}-validator | grep 'name: default$'"
end
