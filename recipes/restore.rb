#Determine if we're using a remote file or a local file.
if(URI(node[:chef_server_populator][:restore][:file]).scheme)
  local_file = File.join(node[:chef_server_populator][:restore][:local_path], 'chef_database_restore.dump')
  remote_file local_file do
    source node[:chef_server_populator][:restore][:file]
  end
  file = local_file
else
  file = node[:chef_server_populator][:restore][:file]
end

if(URI(node[:chef_server_populator][:restore][:data]).scheme)
  local_data = File.join(node[:chef_server_populator][:restore][:local_path], 'chef_data_restore.tar.gz')
  remote_file local_data do
    source node[:chef_server_populator][:restore][:data]
  end
  data = local_data
else
  data = node[:chef_server_populator][:restore][:data]
end

file '/etc/chef/client.pem' do
  action :nothing
end

ruby_block 'set admin public key' do
  block do
    execute_r = run_context.resource_collection.find(:execute => 'update local client')
    execute_r.command "/opt/chef-server/embedded/bin/psql -d opscode_chef -c \"update osc_users set public_key=E'#{%x{openssl rsa -in /etc/chef-server/admin.pem -pubout}}' where username='admin'\""
  end
end

execute 'backup chef server stop' do
  command 'chef-server-ctl stop'
  creates '/etc/chef-server/restore.json'
end

#Drop and Restore entire chef database from file
execute 'dropping chef database' do
  command '/opt/chef-server/embedded/bin/dropdb opscode_chef'
  user 'opscode-pgsql'
  creates '/etc/chef-server/restore.json'
end

execute 'restoring chef data' do
  command "/opt/chef-server/embedded/bin/pg_restore --create --dbname=postgres #{file}"
  user 'opscode-pgsql'
  creates '/etc/chef-server/restore.json'
end

%w( opscode-pgsql opscode_chef opscode_chef_ro ).each do |pg_role|
  execute "set #{pg_role} db permissions" do
    command "/opt/chef-server/embedded/bin/psql -d opscode_chef -c 'GRANT TEMPORARY, CREATE, CONNECT ON DATABASE opscode_chef TO \"#{pg_role}\"'"
    user 'opscode-pgsql'
    creates '/etc/chef-server/restore.json'
  end
end

execute 'restore bookshelf data' do
  command "tar xzf #{data} -C /var/opt/chef-server/bookshelf/"
  creates '/etc/chef-server/restore.json'
end

execute 'update local client' do
  command "/opt/chef-server/embedded/bin/psql -d opscode_chef -c \"update osc_users set public_key=E'#{%x{openssl rsa -in /etc/chef-server/admin.pem -pubout}}' where username='admin'\""
  user 'opscode-pgsql'
  creates '/etc/chef-server/restore.json'
  notifies :delete, 'file[/etc/chef/client.pem]'
end

execute 'restore chef server start' do
  command 'chef-server-ctl start'
  creates '/etc/chef-server/restore.json'
end

execute 'restore chef server wait for erchef' do
  command 'sleep 10'
  creates '/etc/chef-server/restore.json'
end

execute 'restore chef server reindex' do
  command 'chef-server-ctl reindex'
  creates '/etc/chef-server/restore.json'
  retries 5
end

directory '/etc/chef-server'

file '/etc/chef-server/restore.json' do
  content JSONCompat.to_json_pretty(
    :date => Time.now.to_i,
    :file => file
  )
end
