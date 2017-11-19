# SMB::Client

SMB::Client is a wrapper around the smbclient binary installed on your system.

Currently just the SMB2 protocol was tested.

Inspired by the [sambala](https://github.com/lp/sambala) gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smb-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smb-client

## Usage

### Setup

```ruby
options = {
  host: 'Your host',
  user: 'username',
  share: 'share',
  password: 'password',
  version: 2
}
@smb_client = SMB::Client.new options
```

### List directories

Always returns an array with `LsItem` elements.

```ruby
@smb_client.ls
ls_items = @smb_client.ls 'subdirectory/'
# => [#<SMB::ClientHelper::LsItem:0x007f3c58020468 @name=".", @type="D", @size=0, @change_time=2017-11-20 00:02:12 +0100>]
current_dir = ls_items.find { |ls_item| ls_item.name == '.' }
current_dir.file?      # => false
current_dir.directory? # => true
current_dir.hidden?    # => false
```

### Directories

```ruby
@smb_client.mkdir(directory) # => true or raises
@smb_client.rmdir(directory) # => true or raises
```

### Files
```ruby
@smb_client.put(local_path, remote_path) # => true or raises
@smb_client.write(content, local_path)   # => true or raises
@smb_client.del(filename)  # => true or raises
@smb_client.read(filename) # => Reads content of file
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RalfHerzog/smb-client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SMB::Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/RalfHerzog/smb-client/blob/master/CODE_OF_CONDUCT.md).
