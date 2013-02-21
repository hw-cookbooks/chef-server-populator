
execute 'reconfigure chef server!' do
  action :nothing
  command 'chef-server-ctl reconfigure'
end

populator_path = '/opt/chef-server/embedded/cookbooks/chef-server-populator'

directory populator_path do
  action :delete
  only_if do
    File.directory?(populator_path) &&
      !FileUtils.cmp(
        File.join(populator_path, 'metadata.rb'), 
        File.join(Chef::Config[:cookbook_path], 'chef-server-populator/metadata.rb')
      )
  end
end

ruby_block 'vendor chef-server-populator' do
  block do
    FileUtils.cp_r(
      File.join(Chef::Config[:cookbook_path], 'chef-server-populator'), populator_path
    )
  end
  not_if do
    File.directory?(populator_path)
  end
end

file '/opt/chef-server/embedded/cookbooks/dna.json' do
  mode 0644
  content(
    JSON.pretty_generate(
      :run_list => %w(recipe[chef-server]),
      :chef_server => node[:chef_server_populator][:chef_server].to_hash
    )
  )
  notifies :run, "execute[reconfigure chef server!]", :immediately
end
