include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"

ssl_port = ''
if node['chef-server']['configuration']['nginx']['ssl_port']
  ssl_port = ":#{node['chef-server']['configuration']['nginx']['ssl_port']}"
end rescue NoMethodError

knife_opts = "-k #{node[:chef_server_populator][:pem]} \
  -u #{node[:chef_server_populator][:user]} \
  -s https://127.0.0.1#{ssl_port}"

if node[:chef_server_populator][:user_databag]
  begin
    execute 'wait for server' do
      command "counter=1; until [ $counter -gt 10 ] || #{knife_cmd} client list #{knife_opts} > /dev/null 2>&1; do sleep 1; counter=$((counter+1)); do sleep 1; counter=$((counter+1)); done"
      not_if "#{knife_cmd} client list #{knife_opts} > /dev/null 2>&1"
    end
    require 'securerandom'
    data_bag(node[:chef_server_populator][:user_databag]).each do |item_id|
      item = data_bag_item(node[:chef_server_populator][:user_databag], item_id)
      next unless item['chef_server']
      username = item['id']
      pub_key = item['chef_server']['public_key']
      enabled = item['chef_server']['enabled']
puts "FINDME: #{pp item}"
      if enabled
        key_file = "#{Chef::Config[:file_cache_path]}/#{username}.pub"
        password = SecureRandom.urlsafe_base64(23)
        file key_file do
          backup false
          content pub_key
          mode '0400'
        end

        admin_option = item['chef_server']['admin'] ? '--admin' : ''
        execute "create user: #{username}" do
          command "#{knife_cmd} user create #{username} #{admin_option} --user-key #{key_file} -p #{password} -d #{knife_opts}"
          not_if "#{knife_cmd} user list #{knife_opts}| tr -d ' ' | grep '^#{username}$'"
        end
      else
        execute "delete user: #{username}" do
          command "#{knife_cmd} user delete #{username} -y #{knife_opts}"
          only_if "#{knife_cmd} user list #{knife_opts}| tr -d ' ' | grep '^#{username}$'"
        end
      end
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate user population data bag'
  end
end
