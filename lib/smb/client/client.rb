require 'pty'
require 'expect'
require 'open3'
require 'timeout'

require_relative 'connection_error'
require_relative 'runtime_error'

module SMB
  class Client
    attr_accessor :executable, :pid

    def initialize
      @executable = ENV.fetch('SMBCLIENT_EXECUTABLE') { 'smbclient' }
      run '//172.17.0.2/guest1_private pass1 -U guest1 -W WORKGROUP -m SMB2'

      # Pipe used to pass commands to pty
      @read1, @write1 = IO.pipe

      # Pipe used to pass responses from pty
      @read2, @write2 = IO.pipe

      # Indicates if first output should be ignored
      @first_message = true

      @connection_established = false
    end

    def close
      Process.kill('QUIT', @pid) == 1
    end

    def exec(cmd)
      # Send command
      @write1.puts cmd

      # Wait for response
      text = @read2.read

      # Close previous pipe
      @read2.close

      # Create new pipe
      @read2, @write2 = IO.pipe

      # Raise at the end to support continuing
      raise Client::RuntimeError, text if text.start_with? 'NT_STATUS_'

      text
    end

    private

    def run(params)
      # Run +@executable+ in a separate thread to talk to hin asynchronosly
      Thread.start do
        # Spawn the actual +@executable+ pty with +input+ and +output+ handle
        begin
          PTY.spawn(@executable + ' ' + params) do |output, input, pid|
            @pid = pid
            output.sync = true
            input.sync = true

            # Write inputs to pty from +exec+ method
            Thread.start do
              while (line = @read1.readline)
                input.puts line
              end
            end

            @connection_established = true

            # Wait for responses ending with input prompt
            loop do
              output.expect(/smb: \\>$/) { |text| handle_response text }
            end
          end
        rescue Errno::EIO => _
          if @connection_established
            raise StandardError, 'Some unexpected error occoured'
          else
            raise Client::ConnectionError, 'Cannot connect to SMB server'
          end
        end
      end
    end

    def handle_response(text)
      # Write to second pipe so the origin command invocation thread can
      # receive this
      if @first_message
        @first_message = false
        return
      end

      # Format responses
      # Ignore command sent (the first returned line) and the last returned
      # which is the smb prompt
      @write2.write text[0].lines[1..-2].join
      @write2.close
    end
  end
end
