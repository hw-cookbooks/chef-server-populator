#!/usr/bin/env ruby

require 'fog'
require 'multi_json'
require 'mixlib/shellout'

DEFAULT_CONFIGURATION_PATH = '/etc/chef-server/populator/backup.json'

if(ARGV.size > 1 || (ARGV.first && !File.exists?(ARGV.first.to_s)))
  puts 'Usage: chef-server-backup CONFIG_FILE_PATH'
  exit
else
  config = MultiJson.load(
    File.read(
      ARGV.first || DEFAULT_CONFIGURATION_PATH
    ),
    :symbolize_keys => true
  )
end

if(File.exists?(path = '/opt/chef-server/version-manifest.json'))
  server_manifest = MultiJson.load(
    File.read('/opt/chef-server/version-manifest.json'),
    :symbolize_keys => true
  )
  server_version = server_manifest[:version]
elsif(File.exists?(path = '/opt/chef-server/version-manifest.txt'))
  server_version = File.readlines('/opt/chef-server/version-manifest.txt').detect do |line|
    line.include?('version-manifest')
  end.to_s.split(' ').last.strip
else
  server_version = 'UNKNOWN'
end


prefix = [
  Time.now.to_i,
  "ver_#{server_version}",
  config[:filename]
].join('-')

db_file = File.join(
  config[:dir],
  "#{prefix}.dump"
)

data_file = File.join(
  config[:dir],
  "#{prefix}.tgz"
)

begin
  # stop services that write data we're backing up
  %w(opscode-erchef bookshelf).each do |svc|
    stop_service = Mixlib::ShellOut.new("chef-server-ctl stop #{svc}")
    stop_service.run_command
    stop_service.error!
  end

  backup = Mixlib::ShellOut.new([
      '/opt/chef-server/embedded/bin/pg_dump',
      "opscode_chef --username=opscode-pgsql --format=custom -f #{db_file}"
    ].join(' '),
    :user => 'opscode-pgsql'
  )

  backup.run_command
  backup.error!

  backup_data = Mixlib::ShellOut.new(
    "tar -czf #{data_file} -C /var/opt/chef-server/bookshelf data"
  )
  backup_data.run_command
  backup_data.error!
ensure
  start_service = Mixlib::ShellOut.new('chef-server-ctl start')
  start_service.run_command
  start_service.error!
end

remote_creds = [:remote, :connection].inject(config) do |memo, key|
  memo[key] || break
end
remote_directory = [:remote, :directory].inject(config) do |memo, key|
  memo[key] || break
end

if(remote_creds)
  if(remote_directory)
    remote = Fog::Storage.new(remote_creds)
    directory = remote.directories.create(:key => remote_directory)
    [db_file, data_file].each do |file|
      name = File.basename(file)
      directory.files.create(:key => name, :body => open(file))
      directory.files.create(:key => "latest#{File.extname(file)}", :body => open(file))
    end
  else
    $stderr.puts 'ERROR: No remote directory defined for backup storage!'
    exit -1
  end
else
  puts 'WARN: No remote credentials found. Backup is local only!'
end
