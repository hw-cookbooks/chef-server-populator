if(node[:chef_server_populator][:servername_override])
  node.set[:chef_server][:nginx][:server_name] = node[:chef_server_populator][:servername_override]
  node.set[:chef_server][:bookshelf][:vip] = node[:chef_server_populator][:servername_override]
  node.set[:chef_server][:lb][:api_fqdn] = node[:chef_server_populator][:servername_override] 
  node.set[:chef_server][:lb][:web_ui_fqdn] = node[:chef_server_populator][:servername_override] 
else
  node.set[:chef_server][:nginx][:server_name] = node[:fqdn]
  node.set[:chef_server][:bookshelf][:vip] = node[:fqdn]
  node.set[:chef_server][:lb][:api_fqdn] = node[:fqdn] 
  node.set[:chef_server][:lb][:web_ui_fqdn] = node[:fqdn] 
end

include_recipe 'chef-server'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
knife_opts = "-k #{node[:chef_server_populator][:pem]} " <<
  "-u #{node[:chef_server_populator][:user]} " <<
  "-s https://127.0.0.1"
pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

if(Chef::Config[:solo])
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
else
  if(node[:chef_server_populator][:databag] && node[:chef_server_populator][:databag_item])
    begin
      bag = data_bag_item(node[:chef_server_populator][:databag], node[:chef_server_populator][:databag_item])
      bag['clients'].each do |client, pub_key|
        execute "create client: #{client}" do
          command "#{knife_cmd} client create #{client} --admin -d #{knife_opts}"
          not_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
        end
        if(pub_key)
          execute "set public key for: #{client}" do
            command "#{pg_cmd} -c \"update clients set public_key = E'#{pub_key}' where name = '#{client}'\""
            user 'opscode-pgsql'
            not_if "#{pg_cmd} -c \"select public_key from clients where name = '#{client}' and public_key = E'#{pub_key}'\" -tqa | grep #{client}"
          end
        end
      end
    rescue Net::HTTPServerException
      Chef::Log.warn 'Chef server populator failed to locate population data bag'
    end
  end
end
if(node[:chef_server_populator][:install_chef_server_cookbooks])
  execute "load nested chef-server cookbook" do
    command "#{knife_cmd} cookbook upload chef-server #{knife_opts} -o /opt/chef-server/embedded/cookbooks"
    not_if do
      output = %x{#{knife_cmd} cookbook show chef-server #{knife_opts}}.to_s
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file('/opt/chef-server/embedded/cookbooks/chef-server/metadata.rb')
      output.split(' ').include?(metadata.version)
    end
  end
  execute "load nested runit cookbook" do
    command "#{knife_cmd} cookbook upload runit #{knife_opts} -o /opt/chef-server/embedded/cookbooks"
    not_if do
      output = %x{#{knife_cmd} cookbook show runit #{knife_opts}}.to_s
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file('/opt/chef-server/embedded/cookbooks/runit/metadata.rb')
      output.split(' ').include?(metadata.version)
    end
  end
  execute "load chef-server-populator cookbook" do
    command "#{knife_cmd} cookbook upload chef-server-populator #{knife_opts} -o /var/chef/cookbooks"
    not_if do
      output = %x{#{knife_cmd} cookbook show chef-server-populator #{knife_opts}}.to_s
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file('/var/chef/cookbooks/chef-server-populator/metadata.rb')
      output.split(' ').include?(metadata.version)
    end
  end
end
