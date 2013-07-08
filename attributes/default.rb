default[:chef_server_populator][:base_path] = '/tmp/chef-server-populator'
default[:chef_server_populator][:clients] = {}
default[:chef_server_populator][:knife_exec] = '/usr/bin/knife'
default[:chef_server_populator][:user] = 'admin'
default[:chef_server_populator][:pem] = '/etc/chef-server/admin.pem'
default[:chef_server_populator][:databag] = nil

default[:chef_server_populator][:endpoint] = nil

# Deprecated in favor of endpoint
default[:chef_server_populator][:servername_override] = nil

# The :chef_server attribute is passed to chef-server cookbook
# Default the ttl since it kills runs with 403s on templates with
# annoying frequency
default[:chef_server_populator][:chef_server][:configuration][:erchef][:s3_url_ttl] = 3600

default[:chef_server_populator][:cookbook_auto_install] = true
