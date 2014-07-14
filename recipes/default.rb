unless(node[:chef_server_populator][:restore][:file].empty?)
  include_recipe 'chef-server-populator::restore'
end

if(Chef::Config[:solo])
  include_recipe 'chef-server-populator::solo'
else
  include_recipe 'chef-server-populator::client'
  include_recipe 'chef-server-populator::user'
end

if((%w(amazon xenserver).include?(node.platform) && node.platform_version.to_i >= 6) || node.platform == 'fedora')
  node.default[:chef_server_populator][:force_init] = 'upstart'
end

package_resource = node.run_context.resource_collection.all_resources.detect do |r|
  r.class == Chef::Resource::Package && r.package_name.include?('chef-server')
end

file '/opt/chef-server/embedded/cookbooks/runit/recipes/default.rb' do
  content lazy{ "include_recipe 'runit::#{node[:chef_server_populator][:force_init]}'" }
  subscribes :create, package_resource, :immediately
  action :nothing
  only_if do
    node[:chef_server_populator][:force_init] &&
      package_resource
  end
end
