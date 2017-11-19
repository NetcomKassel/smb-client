require 'test_helper'

class SMB::ClientTest < Minitest::Test
  # def test_that_it_has_a_version_number
  #   refute_nil ::SMB::Client::VERSION
  # end


  def setup
    # Setup a samba server for example with docker:
    # ```sh
    # docker run -it —name samba -v /mount -d dperson/samba -u "guest1;pass1"
    # -s "guest1_private;/mount/guest1_private;no;no;no;guest1" -w WORKGROUP
    # ```

    options = {
      host: '172.17.0.2',
      user: 'guest1',
      share: 'guest1_private',
      password: 'pass1'
    }
    @smb_client = SMB::Client.new options
  end

  def test_mkdir
    # Create a directory
    @smb_client.exec 'mkdir test'
    # The next time it should result an error (already exist)
    assert_raises SMB::Client::RuntimeError do
      @smb_client.exec 'mkdir test'
    end

    # Remove the directory
    @smb_client.exec 'rmdir test'
    # The next time it should result an error (not existent)
    assert_raises SMB::Client::RuntimeError do
      @smb_client.exec 'rmdir test'
    end
  end

  def test_ls
    @smb_client.exec 'ls'
    assert_raises SMB::Client::RuntimeError do
      @smb_client.exec 'ls SomeThingNotExistent'
    end
  end

  def teardown
    @smb_client.close
  end
end
