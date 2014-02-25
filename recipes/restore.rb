#Determine if we're using a remote file or a local file.
if (URI(node[:chef_server_populator][:restore][:file]).scheme)
  remote_file node[:chef_server_populator][:restore][:local_path] do
    source node[:chef_server_populator][:restore][:file]
  end
  file = node[:chef_server_populator][:restore][:local_path]
else
  file = node[:chef_server_populator][:restore][:file]
end

execute "backup chef server stop" do
  command "chef-server-ctl stop"
  creates '/etc/chef-server/restore.json'
end

#Restore nodes from file
execute "restoring chef data" do
  command "/opt/chef-server/embedded/bin/pg_restore --clean --exit-on-error --dbname=opscode_chef #{file}"
  user 'opscode-pgsql'
  creates '/etc/chef-server/restore.json'
end

execute "backup chef server start" do
  command "chef-server-ctl start"
  creates '/etc/chef-server/restore.json'
end

directory '/etc/chef-server'

file '/etc/chef-server/restore.json' do
  content JSONCompat.to_json_pretty(:date => Time.now.to_i,
                                    :file => file)
end
