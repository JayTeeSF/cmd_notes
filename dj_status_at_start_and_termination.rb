
# delayed_job-2.1.4/lib/delayed/worker.rb
# i.e.
# iminds@tm25-s00186 /data/inquisitiveminds/current $ bundle exec gem which delayed_job
# /data/inquisitiveminds/shared/bundled_gems/ruby/1.9.1/gems/delayed_job-2.1.4/lib/delayed_job.rb
# =>
# /data/inquisitiveminds/shared/bundled_gems/ruby/1.9.1/gems/delayed_job-2.1.4/lib/delayed/worker.rb


def report_status(state="unk")
  f = File.open("/tmp/dj_status_on_exit.txt", "a")
  f.puts "#{state} @ #{Time.now}: pid: #{Process.pid.inspect}\tsymbol: #{Symbol.all_symbols.size}\tobjects: #{ObjectSpace.count_objects.inspect}\tmemory: #{(`ps -o rss= -p #{Process.pid}`.to_f / 1024).inspect}"
  f.close
end

# modify existing 'trap':
report_status("start") # at top of start method, too

trap('TERM') {say 'Exiting...'; report_status("end"); $exit = true }
