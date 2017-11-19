require 'test_helper'

class SMB::ClientTest < Minitest::Test
  # def test_that_it_has_a_version_number
  #   refute_nil ::SMB::Client::VERSION
  # end

  def test_mkdir
    smb_client = SMB::Client.new

    # Create a directory
    smb_client.exec 'mkdir test'
    # The next time it should result an error (already exist)
    assert_raises SMB::Client::RuntimeError do
      smb_client.exec 'mkdir test'
    end

    # Remove the directory
    smb_client.exec 'rmdir test'
    # The next time it should result an error (not existent)
    assert_raises SMB::Client::RuntimeError do
      smb_client.exec 'rmdir test'
    end
    smb_client.close
  end

  def test_ls
    smb_client = SMB::Client.new
    smb_client.exec 'ls'
    assert_raises SMB::Client::RuntimeError do
      smb_client.exec 'ls SomeThingNotExistent'
    end
    smb_client.close
  end
end
