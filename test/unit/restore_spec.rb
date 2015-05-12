require_relative 'spec_helper'

describe 'chef-server-populator::restore' do
  let(:restore_path) { '/tmp/chef_restore' }
  let(:restore_lock) { '/etc/opscode/restore.json' }
  let(:db_restore_user) { 'opscode-pgsql' }
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set[:chef_server_populator][:restore][:local_path] = restore_path
    end.converge(described_recipe)
  end

  context 'when provided a URL for the database dump' do
    it 'downloads the remote file' do
      chef_run.node.set[:chef_server_populator][:restore][:file] = 'https://www.example.com/restore.dump'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_remote_file(File.join(restore_path, 'chef_database_restore.dump'))
    end
  end

  context 'when provided a URL for the tarball' do
    it 'downloads the remote file' do
      chef_run.node.set[:chef_server_populator][:restore][:data] = 'https://www.example.com/restore.tgz'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_remote_file(File.join(restore_path, 'chef_data_restore.tar.gz'))
    end
  end

  context 'when provided a local path for the database dump' do
    it 'does not download a remote file' do
      expect(chef_run).to_not create_remote_file(File.join(restore_path, 'chef_data_restore.dump'))
    end
  end

  context 'when provided a local path for the tarball' do
    it 'does not download a remote file' do
      expect(chef_run).to_not create_remote_file(File.join(restore_path, 'chef_data_restore.tar.gz'))
    end
  end

  it 'stops all chef server services before restoring' do
    expect(chef_run).to run_execute('backup chef server stop').with(
      :creates => restore_lock
    )
  end

  it 'starts postgres before restoring' do
    expect(chef_run).to run_execute('restore chef server start postgres').with(
      :creates => restore_lock
    )
  end

  it 'restores database dump to postgres' do
    expect(chef_run).to run_execute('restoring chef data').with(
      :user => db_restore_user,
      :creates => restore_lock
    )
  end

  it 'removes existing data' do
    expect(chef_run).to run_execute('remove existing data').with(
      :creates => restore_lock
    )
  end

  it 'restores data from tarball' do
    expect(chef_run).to run_execute('restore tarball data').with(
      :creates => restore_lock
    )
  end

  it 'restarts all chef server services' do
    expect(chef_run).to run_execute('restore chef server restart').with(
      :creates => restore_lock
    )
  end

  it 'pauses to give opscode-erchef time to start' do
    expect(chef_run).to run_execute('restore chef server wait for opscode-erchef').with(
      :creates => restore_lock
    )
  end

  it 'reindexes all orgs on the server' do
    expect(chef_run).to run_execute('restore chef server reindex').with(
      :creates => restore_lock
    )
  end

  it 'creates directory for restore lockfile' do
    expect(chef_run).to create_directory(File.dirname(restore_lock))
  end

  it 'creates restore lockfile' do
    expect(chef_run).to render_file(restore_lock)
  end
end
