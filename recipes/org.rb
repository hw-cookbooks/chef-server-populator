org = node[:chef_server_populator][:populator_org]

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:name]} #{org[:full_name]}"
end

execute 'add populator org validator key' do
  command "chef-server-ctl add-client-key #{org[:name]} #{org[:name]}-validator #{org[:validator_pub_key]} --key-name populator"
end

execute 'remove populator org default validator key' do
  command "chef-server-ctl delete-client-key #{org[:name]} #{org[:name]}-validator default"
end
