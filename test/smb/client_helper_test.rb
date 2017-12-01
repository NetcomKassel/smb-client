require_relative '../test_helper'

require 'tempfile'

class SMB::ClientHelperTest < Minitest::Test
  def setup
    @smb_client = SMB::Client.new SMB_CLIENT_OPTIONS
  end

  def test_ls
    ls_items = @smb_client.ls
    assert ls_items
    assert ls_items.length >= 2

    # Must haves :)
    dir1 = ls_items.find { |ls_item| ls_item.name == '.' }
    assert dir1
    assert_equal false, dir1.file?
    assert_equal true, dir1.directory?
    assert_equal false, dir1.hidden?

    dir2 = ls_items.find { |ls_item| ls_item.name == '..' }
    assert dir2
    assert_equal false, dir2.file?
    assert_equal true, dir2.directory?
    assert_equal false, dir2.hidden?
  end

  def test_dir
    directory = 'test_dir'

    # Create directory
    assert_equal true, @smb_client.mkdir(directory)
    # Do not raise error (directory already exist)
    assert_equal false, @smb_client.mkdir(directory, false)
    # Raise error (directory already exist)
    assert_raises SMB::Client::RuntimeError do
      assert @smb_client.mkdir(directory)
    end

    ls_items = @smb_client.ls directory
    assert_equal true, !ls_items.empty?
    assert_equal 'D', ls_items[0].type
    assert_equal true, ls_items[0].directory?
    assert_equal false, ls_items[0].file?

    # Delete directory
    assert_equal true, @smb_client.rmdir(directory)
    # Do not raise error (directory does not exist)
    assert_equal false, @smb_client.rmdir(directory, false)
    # Raise error (directory does not exist)
    assert_raises SMB::Client::RuntimeError do
      assert @smb_client.rmdir(directory)
    end
  end

  def test_file
    content = 'SomeContent' # 11 bytes
    tempfile = Tempfile.new
    tempfile << content
    tempfile.close
    filename = 'test_file'

    ### Upload
    ls_items = @smb_client.ls(filename, false)
    !ls_items.empty? && @smb_client.del(filename)

    assert_equal true, @smb_client.put(tempfile.path, filename)

    # Already exist
    assert_raises SMB::Client::RuntimeError do
      assert_equal true, @smb_client.put(tempfile.path, filename)
    end

    # Do not overwrite but do not raise error
    assert_equal false, @smb_client.put(tempfile.path, filename, false, false)

    # Overwrite file
    assert_equal true, @smb_client.put(tempfile.path, filename, true)

    # Write content
    assert_equal true, @smb_client.write(content, filename, true)

    ### Get
    get_file_path = @smb_client.get(filename)
    assert get_file_path
    assert_equal File.size(tempfile.path), File.size(get_file_path)

    # Read content
    assert_equal content, @smb_client.read(filename)

    ### Delete
    assert_equal true, @smb_client.del(filename, false)

    # Already deleted without error
    assert_equal false, @smb_client.del(filename, false)

    # Already deleted with error
    assert_raises SMB::Client::RuntimeError do
      assert_equal false, @smb_client.del(filename)
    end

    tempfile.unlink
  end

  def teardown
    @smb_client.close
  end
end
