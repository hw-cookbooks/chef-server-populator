include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
knife_opts = "-s https://127.0.0.1/#{node[:chef_server_populator][:populator_org]} -c /etc/opscode/pivotal.rb"
pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

node[:chef_server_populator][:clients].each do |client, pub_key|
  execute "create client: #{client}" do
    command "#{knife_cmd} client create #{client} --admin -d #{knife_opts} > /dev/null"
    not_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
    retries 5
  end
  if(pub_key && node[:chef_server_populator][:base_path])
    pub_key_path = File.join(node[:chef_server_populator][:base_path], pub_key)
    execute "remove default public key for #{client}" do
      command "chef-server-ctl delete-client-key #{node[:chef_server_populator][:server_org]} #{client} default"
    end
    execute "set public key for: #{client}" do
      command "chef-server-ctl add-client-key #{node[:chef_server_populator][:server_org]} #{client} #{pub_key_path} --key-name populator"
    end
  end
end

execute 'install chef-server-populator cookbook' do
  command "#{knife_cmd} cookbook upload chef-server-populator #{knife_opts} -o #{Chef::Config[:cookbook_path].join(':')} --include-dependencies"
  only_if do
    node[:chef_server_populator][:cookbook_auto_install]
  end
  retries 5
end
