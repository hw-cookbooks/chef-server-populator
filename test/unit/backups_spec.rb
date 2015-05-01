require 'spec_helper'

describe 'chef-server-populator::backups' do
  let(:chef_run) { ChefSpec::SoloRunner.new(:platform => 'ubuntu', :version => '14.04').converge(described_recipe) }
  it 'runs no tests' do
    expect(chef_run)
  end
end
