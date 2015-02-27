#!/usr/bin/env ruby

class ServerControl
  SERVERS = [ ...  ] # FIXME
  USER = '...' # FIXME

  PATCHED = 'not vulnerable'
  def patched?(server)
    PATCHED == remote_execute('wget https://dl.dropboxusercontent.com/u/6867373/CVE-2015-0235.c && gcc CVE-2015-0235.c -o CVE-2015-0235 && ./CVE-2015-0235', server).chomp
  end

  def remote_execute(command, machine_name='some_server')
    command = %Q(time ssh #{USER}@#{machine_name} #{command})
    execute(command, machine_name, _force=true)
  end

  def cleanup_patch_verifier(server)
    remote_execute('rm CVE-2015-0235 CVE-2015-0235.c', server)
  end

  def execute(command, machine_name='some_server', force=false)
    if force
      result = %x{#{command}}
      puts "\n#{machine_name}:#{command}\n\t=> #{result}"
    else
      puts "command: #{command}"
    end
  end

  def patch
    SERVERS.each do |server|
      warn "server: #{server}"
      unless patched?(server)
      warn "patching..."
        command = %Q(time ssh #{USER}@#{server} 'yes Y | sudo -S aptitude update')
        execute(command, server)
        command = %Q(time ssh #{USER}@#{server} 'yes N | sudo -S aptitude safe-update')
        execute(command, server)
      end
      unless patched?(server)
        cleanup_patch_verifier(server)
        fail('unable to patch this server')
      end
      cleanup_patch_verifier(server)
      warn "done"
      return # debug
    end
  end

  def help
    warn "#{$PROGRAM_NAME} help|patch"
  end
end

if __FILE__ == $0
  server_control = ServerControl.new
  case ARGV.first
  when /patch/i
    server_control.patch
  else
    server_control.help
  end
end
