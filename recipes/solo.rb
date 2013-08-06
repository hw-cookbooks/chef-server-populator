include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
knife_opts = "-k #{node[:chef_server_populator][:pem]} " <<
  "-u #{node[:chef_server_populator][:user]} " <<
  "-s https://127.0.0.1"
pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

node[:chef_server_populator][:clients].each do |client, pub_key|
  execute "create client: #{client}" do
    command "#{knife_cmd} client create #{client} --admin -d #{knife_opts}"
    not_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
  end
  if(pub_key && File.directory?(node[:chef_server_populator][:base_path]))
    pub_key_path = File.join(node[:chef_server_populator][:base_path], pub_key)
    if(File.exists?(pub_key_path))
      pub_key_con = File.read(pub_key_path)
      execute "set public key for: #{client}" do
        command "#{pg_cmd} -c \"update clients set public_key = E'#{pub_key_con}' where name = '#{client}'\""
        user 'opscode-pgsql'
      end
    end
  end
end

execute 'install chef-server-populator cookbook' do
  command "#{knife_cmd} cookbook upload chef-server-populator #{knife_opts} -o #{Chef::Config[:cookbook_path].join(':')} --include-dependencies"
  only_if do
    node[:chef_server_populator][:cookbook_auto_install]
  end
end
