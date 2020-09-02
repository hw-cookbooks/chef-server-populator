require_relative './spec_helper'

describe 'backup-script-installed' do
  describe file('/usr/local/bin/chef-server-backup') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_executable.by('owner') }
  end
end

describe 'backups-configured' do
  describe file('/etc/chef-server/populator/backup.json') do
    it { should be_file }
    it { should be_owned_by 'root' }
    its(:content) { should match %r{"dir": "/tmp/chef-server/backup"} }
    its(:content) { should match /"filename": "chef-server-full"/ }
    it { should be_readable.by('owner') }
  end
end

describe 'creates-backups' do
  describe command('PATH=/opt/chef/embedded/bin:$PATH /usr/local/bin/chef-server-backup') do
    its(:exit_status) { should eq 0 }
  end
end

describe 'creates-cron-job' do
  describe cron do
    it { should have_entry '33 3 * * * /usr/local/bin/chef-server-backup' }
  end
end
