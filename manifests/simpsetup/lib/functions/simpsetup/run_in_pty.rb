# Takes an array of input and an array of prompts expected
# and runs a command in a pty.
#
Puppet::Functions.create_function(:'simpsetup::run_cmd_pty') do
#!/usr/bin/env ruby

  dispatch :run_in_pty do
    required_param  'String',  :cmd
    required_param  'Array',   :expect_array
    optional_param  'Integer', :pty_timeout
  end

  def run_in_pty(cmd, expect_array, pty_timeout = 15)
    require 'expect'
    require 'pty'

    outstuff = ''

    PTY.spawn( cmd ) do |r,w,pid|
      w.sync = true

      expect_array.each do |reg,stdin|
        begin
          r.expect( reg, pty_timeout) do |s|
            w.puts stdin
          end
        rescue Errno::EIO
        end

      end

      Process.wait(pid) # set $? to the correct exit code
      begin
        r.each { |l| outstuff += l.chomp }
      rescue Errno::EIO
      end
    end
    exit_code = $?
    if  exit_code.exitstatus == 0
      outstuff
    else
      "Error"
    end
  end
end
