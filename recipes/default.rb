require 'open-uri'
require 'openssl'

file '/tmp/chef_client_config.rb' do
  content 'ssl_verify_mode :verify_none'
end

if(Chef::Config[:solo])
  include_recipe 'chef-server-populator::solo'
else
  include_recipe 'chef-server-populator::client'
end

if(!node[:chef_server_populator][:restore][:file].empty? &&
    node[:chef_server_populator][:restore][:file] != 'none')
  include_recipe 'chef-server-populator::restore'
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

ruby_block 'chef server readiness wait' do
  block do
    response = open('https://localhost/_status',
      :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
    ).read
    unless(Chef::JSONCompat.from_json(response)['status'] == 'pong')
      raise 'Chef server not in ready state'
    end
  end
  retries 10
end
