$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'smb/client'
require 'minitest/autorun'
require 'pp'

# Setup a samba server for example with docker:
#
# ```sh
# docker run -it --name samba -v /mount -d dperson/samba -u "guest1;pass1" -s "guest1_private;/mount;no;no;no;guest1" -w WORKGROUP
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' samba
# ```
#
# Insert the IP below

SMB_CLIENT_OPTIONS = {
  user: 'guest1',
  share: 'guest1_private',
  password: 'pass1',
  version: 2,
  host: '172.17.0.2',
  workgroup: 'WORKGROUP'
}.freeze
