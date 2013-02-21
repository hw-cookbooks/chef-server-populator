
execute 'reconfigure chef server!' do
  action :nothing
  command 'chef-server-ctl reconfigure'
end

file "/opt/chef-server/embedded/cookbooks/dna.json" do
  mode 0644
  content(
    JSON.pretty_generate(
      :run_list => %w(recipe[chef-server]),
      :chef_server => node[:chef_server_populator][:chef_server].to_hash
    )
  )
  notifies "execute[reconfigure chef server!]", :immediately
end
