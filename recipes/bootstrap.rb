directory '/etc/chef/'

cookbook_file '/etc/chef/client.rb'

include_recipe 'chef-server-populator'

