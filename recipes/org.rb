org = node[:chef_server_populator][:populator_org]

directory org[:validator_dir]

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:name]} #{org[:full_name]} -f #{File.join(org[:validator_dir],org[:name])}-validator.pem"
end

execute 'update populator org validator' do
  command "/opt/opscode/embedded/bin/psql -d opscode_chef -c \"update clients set public_key=E'#{File.read(node[:chef_server_populator][:populator_org][:validator_pub_key])}' where name='#{org[:name]}-validator';\""
  user 'opscode-pgsql'
  not_if %Q(sudo -i -u opscode-pgsql #{pg_cmd} -c "select name from clients where name = '#{client}' and public_key = E'#{pub_key.gsub("\n", '\\n')}'" -tq | tr -d ' ' | grep '^#{client}$')
end

