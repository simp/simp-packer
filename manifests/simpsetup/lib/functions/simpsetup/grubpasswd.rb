# Takes an array of input and an array of prompts expected
# and runs a command in a pty.
#
Puppet::Functions.create_function(:'simpsetup::grubpasswd') do
#!/usr/bin/env ruby

  dispatch :grubpasswd do
    required_param  'String',  :cmd
    required_param  'String',  :password
    required_param  'Array',   :expect_array
    optional_param  'Integer', :pty_timeout
  end

  def grubpasswd((cmd, passwd,expect_array, pty_timeout = 15)
    expected = expect_array.map { |x| [x, passwd] }
    output_tmp = run_in_pty(cmd,expected, pty_timeout)
    output  = output_tmp.split(' ').last
  end

  def run_in_pty(cmd, expect_array, pty_timeout)
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
      fail("simpsetup::grubpasswd: Error, #{cmd} failed with error #{exit_code}")
    end
  end
end
