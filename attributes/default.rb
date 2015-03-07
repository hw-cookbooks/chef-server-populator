default[:chef_server_populator][:configuration_directory] = '/etc/chef-server/populator'
default[:chef_server_populator][:base_path] = '/tmp/chef-server-populator'
default[:chef_server_populator][:clients] = {}
default[:chef_server_populator][:knife_exec] = '/usr/bin/knife'
default[:chef_server_populator][:user] = 'admin'
default[:chef_server_populator][:pem] = '/etc/chef-server/admin.pem'
default[:chef_server_populator][:databag] = nil
default[:chef_server_populator][:user_databag] = nil

default[:chef_server_populator][:endpoint] = nil

# Deprecated in favor of endpoint
default[:chef_server_populator][:servername_override] = nil

# The :chef_server attribute is passed to chef-server cookbook
# Default the ttl since it kills runs with 403s on templates with
# annoying frequency
default[:chef_server_populator][:chef_server][:configuration][:opscode_erchef][:s3_url_ttl] = 3600

default[:chef_server_populator][:cookbook_auto_install] = true

# ref: https://tickets.opscode.com/browse/CHEF-3838
default[:chef_server_populator][:force_init] = false # upstart or sysvinit

default[:chef_server_populator][:restore][:file] = ''
default[:chef_server_populator][:restore][:data] = ''
default[:chef_server_populator][:restore][:local_path] = '/tmp/'

default[:chef_server_populator][:backup][:dir] = '/tmp/chef-server/backup'
default[:chef_server_populator][:backup][:filename] = 'chef-server-full'
default[:chef_server_populator][:backup][:remote][:connection] = {}
default[:chef_server_populator][:backup][:remote][:directory] = nil
default[:chef_server_populator][:backup][:schedule] = {
  :minute => '33',
  :hour => '3'
}

# Chef 12 Premium Features, Enable at your own risk, they may cost $$$
# https://www.chef.io/chef/#plans-and-pricing

default[:chef_server_populator][:premium] = {
  'opscode-reporting' => {},
  'opscode-manage' => {
    :enabled => true,
    :config => {
      :disable_sign_up => true
    },
    'opscode-analytics' => {},
    'opscode-push-jobs-server' => {}
  }
}

default[:chef_server_populator][:orgs] = {
  :populator => {
    :name => 'inception_llc',
    :full_name => 'Chef Inception Organization'
  }
}

default[:chef_server_populator][:org_users] = {
  :populator => {
    :first => 'Populator',
    :last => 'User',
    :email => 'user@example.com'
  }
}

default[:chef_server_populator][:server_org] = 'inception_llc'
default[:chef_server_populator][:default_org] = default[:chef_server_populator][:server_org]
