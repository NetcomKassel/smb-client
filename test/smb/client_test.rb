require 'test_helper'

class SMB::ClientTest < Minitest::Test
  def setup
    @smb_client = SMB::Client.new SMB_CLIENT_OPTIONS
  end

  def teardown
    @smb_client.close
  end
end
