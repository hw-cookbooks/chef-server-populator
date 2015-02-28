org = node[:chef_server_populator][:populator_org]

directory org[:validator_dir]

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:name]} #{org[:full_name]} -f #{File.join(org[:validator_dir],org[:name])}-validator.pem"
end

# execute 'update populator org validator' do
#   command "
# end
