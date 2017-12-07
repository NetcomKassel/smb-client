require 'pty'
require 'expect'
require 'open3'
require 'timeout'

require_relative 'connection_error'
require_relative 'client_helper'
require_relative 'runtime_error'

module SMB
  # Low-level interface to smbclient executable
  class Client
    include ClientHelper

    attr_accessor :executable, :pid

    # Creates a new instance and connects to server
    # @param [Hash] options Hash with connection options
    def initialize(options = {})
      @executable = ENV.fetch('SMBCLIENT_EXECUTABLE') { 'smbclient' }
      @options = {
        user: options[:user],
        share: options[:share],
        password: options[:password],
        version: options[:version] || 2,
        host: options[:host] || 'localhost',
        workgroup: options[:workgroup] || 'WORKGROUP'
      }

      Thread.abort_on_exception = true
      connect

      # Pipe used to pass commands to pty
      @read1, @write1 = IO.pipe

      # Pipe used to pass responses from pty
      @read2, @write2 = IO.pipe

      # Indicates if first output should be ignored
      @first_message = true

      @connection_established = false
      @shutdown_in_progress = false
    end

    # Closes the connection to the server end terminates all running threads
    def close
      @shutdown_in_progress = true
      Process.kill('QUIT', @pid) == 1
    end

    # Execute a smbclient command
    # @param [String] cmd The command to be executed
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

    # Connect to the server using separate threads and pipe for communications
    def connect
      # Run +@executable+ in a separate thread to talk to hin asynchronously
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

            # Wait for responses ending with input prompt
            loop do
              output.expect(/smb: \\>$/) { |text| handle_response text }
            end
          end
        rescue Errno::EIO => e
          unless @shutdown_in_progress
            if @connection_established
              raise StandardError, "Unexpected error: [#{e.message}]"
            else
              raise Client::ConnectionError, 'Cannot connect to SMB server'
            end
          end
        end
      end
    end

    # Returns the parameters for the +smbclient+ command
    # @return [String] The parameters
    def params
      @options.map do |k, v|
        v.nil? && raise(Client::RuntimeError, "Missing option [:#{k}]")
      end
      "//#{@options[:host]}/#{@options[:share]} #{@options[:password]} \
-U #{@options[:user]} -W #{@options[:workgroup]} -m SMB#{@options[:version]}"
    end

    # Handles a response from smbclient
    def handle_response(text)
      # Write to second pipe so the origin command invocation thread can
      # receive this
      if @first_message
        @first_message = false
        # TODO: Filter for server information? => Domain, OS and Server

        @connection_established = true
        return
      end

      # Format responses
      # Ignore command sent (the first returned line) and the last returned
      # which is the smb prompt ("smb: \>")
      @write2.write text[0].lines[1..-2].join
      @write2.close
    end
  end
end
