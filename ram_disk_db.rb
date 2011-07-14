class RamDiskDb

  # 344     1   0:00.03 /bin/sh /usr/local/Cellar/mysql/5.5.10/bin/mysqld_safe --datadir=/usr/local/var/mysql --pid-file=/usr/local/var/mysql/mac-josgarcia.affinitylabs.com.pid
  # 717   344   3:27.28 /usr/local/Cellar/mysql/5.5.10/bin/mysqld --basedir=/usr/local/Cellar/mysql/5.5.10 --datadir=/usr/local/var/mysql --plugin-dir=/usr/local/Cellar/mysql/5.5.10/lib/plugin --log-error=/usr/local/var/mysql/mac-josgarcia.affinitylabs.com.err --pid-file=/usr/local/var/mysql/mac-josgarcia.affinitylabs.com.pid --port=3306
  # db's located here:
  # /usr/local/var/mysql/chemistry_test
  attr_accessor :ramdisk_size
  attr_accessor :disk_dev
  attr_accessor :volume_name
  attr_accessor :port

  def default_num_megabytes
    256
  end

  def default_volume_name
    'ramdisk'
  end

  def mount_point
    # "/Volumes/#{volume_name}"
    #"~/#{volume_name}"
    "/Users/jaytee/#{volume_name}"
  end
  def initialize(num_megabytes=default_num_megabytes, _volume_name=default_volume_name)
    @ramdisk_size = calculate_ramdisk_size(num_megabytes)
    @volume_name = _volume_name
    @port = 3308
  end

  def create_ramdisk
    cmd = "hdiutil attach -nomount ram://#{ramdisk_size}"
    puts "creating ramdisk: #{cmd}"
    self.disk_dev = %x{#{cmd}}
    self.disk_dev.strip!
    puts "disk_dev is set to: >#{disk_dev}<"
    #unless disk_dev
    #  puts "unable to set disk_dev: #{disk_dev}"
    #  return
    #end
    #cmd = %Q{diskutil eraseVolume HFS+ "#{volume_name}" #{disk_dev}}
    # doesn't work: cmd = %Q{diskutil eraseVolume HFS+ "#{mount_point}" #{disk_dev}}
    cmd = "newfs_hfs -v #{volume_name} #{disk_dev}"
    puts "creating device: #{cmd}"
    puts %x{#{cmd}}

    cmd = "mkdir -p #{mount_point}"
    puts "creating mount-point: #{cmd}"
    puts %x{#{cmd}}

    cmd = "mount -o noatime -t hfs #{disk_dev} #{mount_point}"
    puts "mounting: #{cmd}..."
    puts %x{#{cmd}}

    # puts "is diskutil still running ?!: #{`ps -eafwww | grep diskutil`}"
    # /dev/disk1 on /Volumes/ramdisk (hfs, local, nodev, nosuid, noowners, mounted by jaytee)
    #puts "current mounting: #{`mount`}"
    #cmd = "diskutil disableJournal #{mount_point}"
    #puts "disabling journaling: #{cmd}"
    #puts %x{#{cmd}}
    #cmd = "umount #{disk_dev}"
    #puts "unmounting: #{cmd}..."
    #puts %x{#{cmd}}

    puts "mount(s): #{`mount`}"
    puts "Done creating ramdisk: #{disk_dev}"
  end

  def install_db
    cmd = "#{mysql_install_cmd} #{default_mysql_params}"
    puts "installing db: #{cmd}"
    puts %x{#{cmd}}
    puts "db installed."
  end

  def start_mysql
    cmd = " #{mysql_daemon} " \
          " #{default_mysql_params} " \
          " #{log_error_param} " \
          " #{pid_file_param} " \
          " #{port_param} " \
          " #{plugin_param} " \
          " #{socket_param} "
    puts "starting mysql (in bkgrnd) w/: #{cmd}"
    puts %x{#{cmd} &}
    sleep 2
    puts "mysql started (in bkgrnd)."
  end

  def kill_ramdisk
    cmd = "hdiutil detach #{disk_dev}"
    puts %x{#{cmd}}
    puts "Ramdisk killed."
  end

  def setup_dbs
    cmd = "#{mysql_cmd} " \
          " #{mysql_root_user_param} " \
          " #{socket_param} " \
          " #{mysql_setup_cmd_param}"

    puts "setting-up mysql db(s) w/: #{cmd}"
    puts %x{#{cmd}}
  end

  def test_mysql
    cmd = "#{mysql_cmd} " \
          " #{mysql_root_user_param} " \
          " #{socket_param} " \
          " #{mysql_sample_cmd_param}"

    puts "testing mysql connection w/: #{cmd}"
    puts %x{#{cmd}}
  end

  # /usr/local/Cellar/mysql/5.5.10/bin/mysql.server start
  # dbs stored here:

  private

  def mysql_setup_cmd_param
    %Q{-e "create DATABASE chemistry_development; create DATABASE chemistry_test;"}
  end

  def mysql_sample_cmd_param
    %Q{-e "SHOW DATABASES;"}
  end

  def mysql_root_user_param
    '-u root'
  end

  def mysql_cmd
    #'/usr/local/Cellar/mysql/5.5.10/bin/mysql'
    '/usr/local/bin/mysql'
  end

  def calculate_ramdisk_size(num_megabytes)
    num_megabytes * 1048576 / 512 # MB * MiB/KB;
  end

  #def mysql_tmp_dir
  #  '--tmpdir='
  #end

  def mysql_base_dir
    '/usr/local/Cellar/mysql/5.5.10'
  end

  def mysql_install_cmd
    # '/usr/local/Cellar/mysql/5.5.10/bin/mysql_install_db'
    '/usr/local/bin/mysql_install_db'
  end

  def mysql_base_dir_param
    "--basedir=#{mysql_base_dir}"
  end

  def mysql_data_dir_param
    "--datadir=#{mount_point}"
  end

  def mysql_user_param
    #'--user=mysql'
    "--user=`whoami`"
  end

  def mysql_verbose_param
    '--verbose'
  end

  def mysql_daemon
    # '/usr/local/Cellar/mysql/5.5.10/bin/mysqld'
    '/usr/local/bin/mysqld'
  end

  def default_mysql_params
    "#{mysql_base_dir_param} #{mysql_data_dir_param} #{mysql_user_param} #{mysql_verbose_param}"
  end

  def socket_param
    "--socket=/tmp/mysql_ram.sock"
  end

  def plugin_param
    "--plugin-dir=/usr/local/Cellar/mysql/5.5.10/lib/plugin"
  end

  def port_param
    "--port=#{port}"
  end

  def pid_file_param
    "--pid-file=#{mount_point}/mysql.ramdisk.pid"
  end

  def log_error_param
    "--log-error=#{mount_point}/mysql.ramdisk.err"
  end

end
