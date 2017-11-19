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

  def teardown
    @smb_client.close
  end
end
