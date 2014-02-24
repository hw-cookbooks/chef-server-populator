file = File.join(node[:chef_server_populator][:backup][:dir], node[:chef_server_populator][:backup][:file])

directory node[:chef_server_populator][:backup][:dir] do
  recursive true
end

execute 'Backup Chef Database' do
  command "/opt/chef-server/embedded/bin/pg_dump opscode_chef -Fc -a > #{file}"
  user 'opscode-pgsql'
end

#Upload to S3
unless(node[:chef_server_populator][:backup][:remote][:connection].empty)
  # Include fog
  %w(gcc libxml2 libxml2-devel libxslt libxslt-devel).each do |fog_dep|
    package fog_dep
  end

  gem_package 'fog'

  ruby_block 'Upload Backup to Remote Storage' do
    block do
      require 'fog'
      remote = Fog::Storage.new( node[:chef_server_populator][:backup][:remote][:connection] )
      directory = node[:chef_server_populator][:backup][:remote][:directory]
      name = File.basename(file)
      directory.files.create(:key => name, :body => open(file))
    end
  end
end
