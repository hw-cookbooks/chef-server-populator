require_relative 'spec_helper'

describe 'chef-server-populator::client' do

  let(:populator_data_bag) { 'populator' }

  let(:knife_cmd) { '/opt/chef/bin/knife' }
  let(:knife_opts) { '-c /etc/opscode/pivotal.rb' }
  let(:list_clients_cmd) { "#{knife_cmd} client list #{knife_opts}" }
  let(:list_client_keys_cmd) { "chef-server-ctl list-client-keys" }
  let(:list_user_keys_cmd) { "chef-server-ctl list-user-keys" }
  let(:list_orgs_cmd) { "chef-server-ctl org-list" }
  let(:test_user_name) { 'murph' }
  let(:test_user_pub_key_path) { "#{Chef::Config[:file_cache_path]}/#{test_user_name}.pub" }
  let(:test_user_item) {
    Mash.new(
      'chef_server' => {
        'email' => 'murphcooper@nasa.gov',
        'full_name' => 'Murphy Cooper',
        'enabled' => true,
        'password' => 'vHeBu6baW4PXIKVNDsE-APweIVpdLLU',
        'client_key' => "",
        'type' => ['user'],
        'orgs' => {
          'nasa' => {
            'enabled' => true,
            'admin' => true
          }
        }
      }
    )
  }

  before do
    stub_command(/#{list_clients_cmd} | tr -d ' ' | grep '^(.*)$'/).and_return(false)
    stub_command(/#{list_client_keys_cmd} .* | grep 'name: populator$'/).and_return(false)
    stub_command(/#{list_orgs_cmd} | grep \'\^.*\$\'/).and_return(false)
    stub_command("#{list_user_keys_cmd} #{test_user_name} | grep 'name: populator$'").and_return(false)
    stub_command("#{list_user_keys_cmd} #{test_user_name} | grep 'name: default$'").and_return(true)
  end

  let(:chef_run) do
    ChefSpec::ServerRunner.new do |node, server|
      node.set[:chef_server_populator][:databag] = populator_data_bag
      server.create_data_bag(populator_data_bag, {
        test_user_name => test_user_item,
        'case' => {
          'chef_server' => {
            'enabled' => true,
            'client_key' => "",
            'type' => ['client']
          },
          'orgs' => ['nasa']
        },
        'tars' => {
          'chef_server' => {
            'enabled' => true,
            'client_key' => "",
            'type' => ['client']
          },
          'orgs' => ['endeavor']
        },
        'nasa' => {
           'chef_server' => {
             'full_name' => 'National Aeronautics and Space Administration',
             'client_key' => "",
             'type' => ['org'],
             'enabled' => true
           }
        },
        'endeavor' => {
          'chef_server' => {
            'full_name' => 'Endeavor Space Mission',
            'client_key' => "",
            'type' => ['org'],
            'enabled' => true
          }
        },
        'millers_planet' => {
          'chef_server' => {
            'full_name' => 'Miller\'s Planet',
            'client_key' => "",
            'type' => ['org'],
            'enabled' => false
          }
        }
      })
    end.converge(described_recipe)
  end

  context 'when an organization is defined in the data bag' do

    context 'when the organization is enabled' do

      it 'creates the organization' do
        expect(chef_run).to run_execute('create org: nasa').with(
          :command => "chef-server-ctl org-create nasa National Aeronautics and Space Administration"
        )
      end

      it 'adds the organziation validator key' do
        expect(chef_run).to run_execute('add org validator key: nasa').with(
          :command => "chef-server-ctl add-client-key nasa nasa-validator --public-key-path #{Chef::Config[:file_cache_path]}/nasa.pub --key-name populator"
        )
      end

    end

    context 'when the organization is disabled' do

      it 'does not create the organization' do
        expect(chef_run).to_not run_execute('create org: millers_planet')
      end

    end

  end

  context 'a user is defined in the data bag' do
    context 'the user is enabled' do
      it 'creates the user' do
        expect(chef_run).to run_execute("create user: #{test_user_name}").with(
          :command => "chef-server-ctl user-create #{test_user_name} #{test_user_item['chef_server']['full_name'].split(' ').first} #{test_user_item['chef_server']['full_name'].split(' ').last} #{test_user_item['chef_server']['email']} #{test_user_item['chef_server']['password']} > /dev/null 2>&1"
        )
      end

      context 'the user has a client key specified' do

        it 'creates the user\'s client key file' do
          expect(chef_run).to create_file(test_user_pub_key_path).with(
            :content => test_user_item['chef_server']['client_key']
          )
        end

        it 'sets inserts the client key as the user\'s populator key' do
          expect(chef_run).to run_execute("set user key: #{test_user_name}").with(
            :command => "chef-server-ctl add-user-key #{test_user_name} --public-key-path #{test_user_pub_key_path} --key-name populator"
          )
        end

        it 'deletes the user\'s default key' do
          expect(chef_run).to run_execute("delete default user key: #{test_user_name}")
        end
      end

      context 'the user has an org specified' do
      end
    end
  end

  context 'when a client is defined in the data bag' do
  end

end
