#!/usr/bin/env ruby

class GemInstallCommander
  attr_reader :gem_list

  def initialize(gem_list=%x{gem list})
    @gem_list = gem_list
  end

  def self.canonical_gem_hash_array
    super || nil
  end

  def gem_list_to_gem_hash_array(gems)
    return [] unless gems
    gems.collect do |gem_line|
      if gem_line[/^(\S+)\s+\((.*)\)/]
        name, versions = $1, $2
        version_ary = versions.split(/, /)
        {name => version_ary}
      end
    end
  end

  def installed_gems
    return [] unless gem_list
    gem_list.reject do |gem_line|
      gem_line[/^\s*\*/] || !gem_line[/\(\d+/]
    end.map(&:strip!)
  end

  # *** LOCAL GEMS ***
  # 
  # bundler (1.0.10)
  # activesupport (3.0.5, 2.3.5)

  def required_gemset
    @required_gemset ||= GemSet.new(self.class.canonical_gem_hash_array)
  end

  def installed_gemset
    @installed_gemset ||= GemSet.new(
      gem_list_to_gem_hash_array(installed_gems)
    )
  end

  def gen_install_cmds
    # puts required_gemset.to_install_cmds
    gems_to_install.collect do |meta_gem|
      # puts "meta_gem_class: #{meta_gem.class}; #{meta_gem.inspect}"
      meta_gem.to_install_cmd
    end
  end

  def gems_to_install
    @gems_to_install ||= required_gemset - installed_gemset
  end

  def gems_to_uninstall
    @gems_to_uninstall ||= installed_gemset - required_gemset
  end

  def gen_uninstall_cmds
    gems_to_uninstall.collect do |meta_gem|
      meta_gem.to_uninstall_cmd
    end
  end

end

class GemSet
  attr_reader :meta_gems

  def initialize(gem_hash_array)
    @meta_gems = []
    if gem_hash_array
      gem_hash_array.each do |gem_hash|
        name = gem_hash.keys.first
        @meta_gems += gem_hash.values.first.collect do |version|
          MetaGem.new(name, version)
        end.flatten
      end
      # p @meta_gems.inspect
    end
  end

  def -(other_gemset)
    meta_gems.reject do |meta_gem|
      other_gemset.meta_gems.include?(meta_gem)
    end.flatten
  end

  def to_install_cmds
    @meta_gems.collect do |meta_gem|
      meta_gem.to_install_cmd
    end
  end
end

class MetaGem
  attr_reader :name, :version
  def initialize(name, version)
    @name = name
    @version = version
  end

  def to_uninstall_cmd
    "gem uninstall #{@name} -v '#{@version}';"
  end

  def ==(other)
    self.name == other.name && self.version == other.version
  end

  def to_install_cmd
    "gem install #{@name} -v '#{@version}';" # doesn't handle :require => ... or :lib ...
  end
end

module ChemistryGems
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def canonical_gem_hash_array
      [
        {'abstract' => ['1.0.0']},
        {'activemodel' => ['3.0.5']},
        {'activerecord' => ['3.0.5']},
        {'activesupport' => ['3.0.5', '2.3.5']},
        {'arel' => ['2.0.9']},
        {'arrayfields' => ['4.7.4']},
        {'builder' => ['3.0.0', '2.1.2']},
        {'bundler' => ['1.0.10']},
        {'capybara' => ['0.4.1.2']},
        {'capybara-envjs' => ['0.4.0']},
        {'celerity' => ['0.8.8']},
        {'cheat' => ['1.3.0']},
        {'childprocess' => ['0.1.7']},
        {'chronic' => ['0.3.0']},
        {'churn' => ['0.0.13']},
        {'colored' => ['1.2']},
        {'columnize' => ['0.3.2']},
        {'configuration' => ['1.2.0']},
        {'cucumber' => ['0.10.0']},
        {'cucumber-rails' => ['0.3.2']},
        {'culerity' => ['0.2.15']},
        {'database_cleaner' => ['0.6.4']},
        {'delorean' => ['1.0.0']},
        {'diff-lcs' => ['1.1.2']},
        {'envjs' => ['0.3.8']},
        {'erubis' => ['2.6.6']},
        {'factory_girl' => ['1.3.3', '1.2.4']},
        {'fastercsv' => ['1.5.4']},
        {'fattr' => ['2.2.0']},
        {'ffi' => ['1.0.7', '0.6.3']},
        {'flay' => ['1.4.2']},
        {'flog' => ['2.5.1']},
        {'gherkin' => ['2.3.3']},
        {'gpgme' => ['1.0.8']},
        {'growl' => ['1.0.3']},
        {'haml' => ['3.0.25']},
        {'hirb' => ['0.4.0']},
        {'httpclient' => ['2.1.6.1']},
        {'i18n' => ['0.5.0']},
        {'jasmine' => ['1.0.1.1']},
        {'johnson' => ['2.0.0.pre3']},
        {'json' => ['1.4.6']},
        {'json_pure' => ['1.5.1']},
        {'launchy' => ['0.3.7']},
        {'libnotify' => ['0.1.4']},
        {'linecache' => ['0.43']},
        {'little-plugger' => ['1.1.2']},
        {'logging' => ['1.4.3']},
        {'loquacious' => ['1.6.4']},
        {'main' => ['4.4.0', '4.2.0']},
        {'metric_fu' => ['1.5.1']},
        {'mime-types' => ['1.16']},
        {'mocha' => ['0.9.8']},
        {'mysql' => ['2.8.1']},
        {'net-scp' => ['1.0.4']},
        {'net-sftp' => ['2.0.5']},
        {'net-ssh' => ['2.1.3']},
        {'no_peeping_toms' => ['1.1.0']},
        {'nokogiri' => ['1.4.4']},
        {'rack' => ['1.2.1']},
        {'rack-bug' => ['0.3.0']},
        {'rack-test' => ['0.5.7']},
        {'rails_best_practices' => ['0.7.1']},
        {'rake' => ['0.8.7']},
        {'rb-inotify' => ['0.8.4']},
        {'rcov' => ['0.9.9']},
        {'RedCloth' => ['4.2.7']},
        {'redis' => ['2.1.1']},
        {'reek' => ['1.2.8']},
        {'rjb' => ['1.2.6']},
        {'roodi' => ['2.1.0']},
        {'rspactor' => ['0.7.0.beta.7']},
        {'rspec' => ['1.3.0']},
        {'rspec-expectations' => ['2.5.0']},
        {'rspec-mocks' => ['2.5.0']},
        {'rspec-rails' => ['1.3.2']},
        {'ruby-debug' => ['0.10.4']},
        {'ruby-debug-base' => ['0.10.4']},
        {'ruby-progressbar' => ['0.0.9']},
        {'ruby2ruby' => ['1.2.5']},
        {'ruby_parser' => ['2.0.6']},
        {'rubyzip' => ['0.9.4']},
        {'rufus-tokyo' => ['1.0.7']},
        {'Saikuro' => ['1.1.0']},
        {'selenium-client' => ['1.2.18']},
        {'selenium-rc' => ['2.3.2']},
        {'selenium-webdriver' => ['0.1.3']},
        {'sexp_processor' => ['3.0.5']},
        {'sham_rack' => ['1.3.3']},
        {'sinatra' => ['1.2.1']},
        {'soap4r' => ['1.5.8']},
        {'stackdeck' => ['0.2.0']},
        {'sys-uname' => ['0.8.5']},
        {'SystemTimer' => ['1.2.2']},
        {'term-ansicolor' => ['1.0.5']},
        {'test-spec' => ['0.10.0']},
        {'thoughtbot-factory_girl' => ['1.2.2']},
        {'tilt' => ['1.2.2']},
        {'trollop' => ['1.16.2']},
        {'tyrantmanager' => ['1.6.0']},
        {'tzinfo' => ['0.3.24']},
        {'xpath' => ['0.1.3']},
        {'yajl-ruby' => ['0.8.1']}
      ]
    end
  end
end

class GemInstallCommander
  include ChemistryGems
end

puts
to_uninstall = GemInstallCommander.new.gen_uninstall_cmds
if !to_uninstall.empty? 
  puts "please uninstall the following gems:"
  puts to_uninstall
else
  puts "you have no gems to uninstall"
end
puts

puts
to_install = GemInstallCommander.new.gen_install_cmds
if !to_install.empty? 
  puts "please install the following gems:"
  puts to_install
else
  puts "you have no gems to install"
end
puts
