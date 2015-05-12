require_relative './spec_helper'

describe "NO OPs" do

    describe command('chef-server-ctl user-list') do
    its(:stdout) { should_not match /non-chef-user/ }
  end

end
