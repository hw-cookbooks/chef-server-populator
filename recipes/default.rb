if(Chef::Config[:solo])
  include_recipe 'chef-server-populator::solo'
else
  include_recipe 'chef-server-populator::client'

  unless(node[:chef_server_populator][:chef_server].empty?)
    include_recipe 'chef-server-populator::configurator'
  end
end

