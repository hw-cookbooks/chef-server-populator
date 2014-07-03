include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
ssl_port = ''
if node['chef-server']['configuration']['nginx']['ssl_port']
  ssl_port = ":#[node['chef-server']['configuration']['nginx']['ssl_port']}"
end rescue NoMethodError 
knife_opts = "-k #{node[:chef_server_populator][:pem]} " <<
  "-u #{node[:chef_server_populator][:user]} " <<
  "-s https://127.0.0.1#{ssl_port}"
pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

if(node[:chef_server_populator][:databag])
  begin
    data_bag(node[:chef_server_populator][:databag]).each do |item_id|
      item = data_bag_item(node[:chef_server_populator][:databag], item_id)
      next unless item['chef_server']
      client = item['id']
      pub_key = item['chef_server']['client_key']
      enabled = item['chef_server']['enabled']
      if(item['enabled'] == false)
        execute "delete client: #{client}" do
          command "#{knife_cmd} client delete #{client} --admin -d #{knife_opts}"
          only_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
        end
      else
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
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate population data bag'
  end
end

