#Determine if we're using a remote file or a local file.
if (node[:chef_server_populator][:restore][:file]).include?(uri.scheme)
  remote_file node[:chef_server_populator][:restore][:local_path] do
    source node[:chef_server_populator][:restore][:file]
  end
  file = node[:chef_server_populator][:restore][:local_path]
else
  file = node[:chef_server_populator][:restore][:file]
end

#Restore nodes from file
execute "restoring chef data" do
  command "/opt/chef-server/embedded/bin/pg_restore -d opscode_chef #{file}"
  user 'opscode-pgsql'
end
node.set[:chef_server_populator][:restore][:file] = nil
