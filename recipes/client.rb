include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"

ssl_port = %w(chef-server configuration nginx ssl_port).inject(node) do |memo, key|
  memo[key] || break
end
ssl_port = ":#{ssl_port}" if ssl_port

knife_opts = "-k #{node[:chef_server_populator][:pem]} " <<
  "-u #{node[:chef_server_populator][:user]} " <<
  "-s https://127.0.0.1#{ssl_port}"

if(node[:chef_server_populator][:databag])
  begin
    data_bag(node[:chef_server_populator][:databag]).each do |item_id|
      item = data_bag_item(node[:chef_server_populator][:databag], item_id)
      next unless item['chef_server']
      client = item['id']
      pub_key = item['chef_server']['client_key']
      enabled = item['chef_server']['enabled']
      types = [item['chef_server'].fetch('type', 'client')].flatten
      admin = item['chef_server'].fetch('admin', true)
      password = item['chef_server'].fetch('password', SecureRandom.urlsafe_base64(23))
      if(item['enabled'] == false)
        if(types.include?('client'))
          execute "delete client: #{client}" do
            command "#{knife_cmd} client delete #{client} -d #{knife_opts}"
            only_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
        end
        if(types.include?('user'))
          execute "delete user: #{client}" do
            command "#{knife_cmd} user delete #{client} -y #{knife_opts}"
            only_if "#{knife_cmd} user list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
          end
        end
      else
        if(types.include?('client'))
          execute "create client: #{client}" do
            command "#{knife_cmd} client create #{client}#{' --admin' if admin} -d #{knife_opts}"
            not_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
          if(pub_key)
            execute "set public key for: #{client}" do
              command "#{pg_cmd} -c \"update clients set public_key = E'#{pub_key}' where name = '#{client}'\""
              user 'opscode-pgsql'
              not_if %Q(sudo -i -u opscode-pgsql #{pg_cmd} -c "select name from clients where name = '#{client}' and public_key = E'#{pub_key.gsub("\n", '\\n')}'" -tq | tr -d ' ' | grep '^#{client}$')
              end
            end
          end
        end
        if(types.include?('user'))

          key_file = "#{Chef::Config[:file_cache_path]}/#{username}.pub"
          password = SecureRandom.urlsafe_base64(23)
          file key_file do
            backup false
            content pub_key
            mode '0400'
          end

          execute "create user: #{client}" do
            command "#{knife_cmd} user create #{username}#{' --admin' if admin} --user-key #{key_file} -p #{password} -d #{knife_opts}"
            not_if "#{knife_cmd} user list #{knife_opts}| tr -d ' ' | grep '^#{username}$'"
          end

        end
      end
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate population data bag'
  end
end
