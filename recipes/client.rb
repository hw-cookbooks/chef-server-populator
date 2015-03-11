include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
knife_opts = '-c /etc/opscode/pivotal.rb'

ssl_port = %w(chef-server configuration nginx ssl_port).inject(node) do |memo, key|
  memo[key] || break
end
ssl_port = ":#{ssl_port}" if ssl_port

pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

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
      org = item['chef_server'].fetch('org', nil)
      if(item['enabled'] == false)
        if(types.include?('client'))
          execute "delete client: #{client}" do
            command "#{knife_cmd} client delete #{client} -d -s https://127.0.0.1/#{org} -c /etc/opscode/pivotal.rb"
            only_if "#{knife_cmd} client list #{knife_opts} | tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
        end
      end
      if(types.include?('user'))
        execute "delete user: #{client}" do
          command "chef-server-ctl user-delete #{client}"
          only_if "chef-server-list user-list | tr -d ' ' | grep '^#{client}$'"
        end
      else
        if(types.include?('client'))
          execute "create client: #{client}" do
            command "#{knife_cmd} client create #{client}#{' --admin' if admin} -d #{knife_opts}"
            not_if "#{knife_cmd} client list #{knife_opts} | tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
        end
        if(pub_key)
          execute "set public key for: #{client}" do
            command "#{pg_cmd} -c \"update clients set public_key = E'#{pub_key}' where name = '#{client}'\""
            user 'opscode-pgsql'
            #            not_if %Q(sudo -i -u opscode-pgsql #{pg_cmd} -c "select name from clients where name = '#{client}' and public_key = E'#{pub_key.gsub("\n", '\\n')}'" -tq | tr -d ' ' | grep '^#{client}$')
          end
        end
        if(types.include?('user'))

          key_file = "#{Chef::Config[:file_cache_path]}/#{username}.pub"
          file key_file do
            backup false
            content pub_key
            mode '0400'
          end

          execute "create user: #{client}" do
            command "chef-server-ctl user-create #{username} {first_name || 'first'} #{last_name || 'last'} #{email} #{password} > /dev/null"
            not_if "chef-server-ctl user-list | grep '^#{username}$'"
          end
          execute "set user key: #{client}" do
            command "chef-server-ctl add-user-key #{username} {key_file} --key-name populator"
          end
          execute "delete default user key: #{client}" do
            command "chef-server-ctl delete-user-key #{username} default"
            only_if "chef-server-ctl list-user-keys #{username} | grep '^key_name: default$'"
          end
          execute "set user org: #{client}" do
            command "chef-server-ctl org-user-add #{org} #{username} #{'--admin' if admin}"
            not_if org.nil?
          end
        end
      end
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate population data bag'
  end
end
