#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
class GemInstallCommander
  attr_reader :gem_list

  def initialize(gem_list=nil)
    @gem_list = gem_list || %x{gem list}
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
        {'i18n' => ['0.4.1']},
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

module ChemistryVendoredGemsPlus
  def self.append_features(base)
    base.class_eval do
      include ChemistryGems
    end

    base.extend ClassMethods
  end
  module ClassMethods

  def vendored_rails_gem
    {'rails' => ['2.3.5']}
  end

  def vendored_gems
    [
      vendored_rails_gem,
      {'addressable' => ['2.1.2']},
      {'calendar_date_select' => ['1.15']},
      {'hoptoad_notifier' => ['2.4.8']},
      {'json' => ['1.4.6']},
      {'mustache' => ['0.12.0']},
      {'newrelic_rpm' => ['2.9.5']},
      {'rack' => ['1.0.1']},
      {'redis' => ['2.1.1']},
      {'redis-namespace' => ['0.8.0']},
      {'resque' => ['1.10.0']},
      {'rspec' => ['1.3.0']},
      {'ruby-progressbar' => ['0.0.9']},
      {'sinatra' => ['1.0']},
      {'vegas' => ['0.1.8']},
    ]
  end

  def canonical_gem_hash_array
    super + vendored_gems 
  end
end
end

module InstalledGems
  extend self
  def gem_list
    list =<<-EOL
    activemodel (3.0.0)
    activerecord (3.0.0)
    activesupport (3.0.0, 2.3.8)
    arel (1.0.1)
    arrayfields (4.7.4)
    builder (2.1.2)
    capybara (0.4.1.1)
    capybara-envjs (0.4.0)
    celerity (0.8.7)
    childprocess (0.1.6)
    chronic (0.2.3)
    churn (0.0.12)
    columnize (0.3.1)
    cucumber (0.10.0, 0.8.5)
    cucumber-rails (0.3.2, 0.3.1)
    culerity (0.2.15)
    database_cleaner (0.5.2)
    delorean (0.2.0)
    diff-lcs (1.1.2)
    envjs (0.3.8)
    factory_girl (1.3.2)
    fastercsv (1.5.3)
    fattr (2.1.0)
    ffi (0.6.3)
    flay (1.4.0)
    flog (2.4.0)
    gherkin (2.3.3, 2.1.5)
    gpgme (1.0.8)
    hirb (0.3.3)
    hoe (2.6.1)
    httpclient (2.1.5.2)
    i18n (0.4.1)
    jasmine (1.0.1.1)
    johnson (2.0.0.pre3)
    json (1.4.6)
    json_pure (1.4.6)
    linecache (0.43)
    main (4.2.0)
    metric_fu (1.5.1)
    mime-types (1.16)
    mocha (0.9.8)
    mysql (2.8.1)
    net-scp (1.0.2)
    net-sftp (2.0.4)
    net-ssh (2.0.23)
    no_peeping_toms (1.1.0)
    nokogiri (1.4.3.1)
    rack (1.2.1)
    rack-test (0.5.4)
    rails_best_practices (0.4.0)
    rake (0.8.7)
    rcov (0.9.8)
    RedCloth (4.2.3)
    reek (1.2.8)
    rjb (1.2.6)
    roodi (2.1.0)
    rspec (1.3.0)
    rspec-core (2.5.1)
    rspec-expectations (2.5.0)
    rspec-mocks (2.5.0)
    rspec-rails (1.3.2)
    ruby-debug (0.10.3)
    ruby-debug-base (0.10.3)
    ruby2ruby (1.2.4)
    ruby_parser (2.0.4)
    rubyforge (2.0.4)
    rubyzip (0.9.4)
    rufus-tokyo (1.0.7)
    Saikuro (1.1.0)
    selenium-client (1.2.18)
    selenium-rc (2.2.4)
    selenium-webdriver (0.1.2)
    sexp_processor (3.0.4)
    sham_rack (1.3.2)
    soap4r (1.5.8)
    stackdeck (0.2.0)
    SystemTimer (1.2.2)
    term-ansicolor (1.0.5)
    test-spec (0.10.0)
    trollop (1.16.2)
    tzinfo (0.3.23)
    webrat (0.7.1)
    xpath (0.1.3)
    yajl-ruby (0.7.7)
    EOL
  end
end

module JtGems
  extend self
  def gem_list
    list =<<-EOL
    abstract (1.0.0)
    actionmailer (2.3.5)
    actionpack (2.3.5)
    activerecord (2.3.5)
    activeresource (2.3.5)
    activesupport (2.3.5)
    addressable (2.1.2)
    alias (0.2.2)
    arel (2.0.9)
    arrayfields (4.7.4)
    awesome_print (0.4.0, 0.3.2)
    boson (0.3.3)
    builder (3.0.0, 2.1.2)
    bundler (1.0.10)
    calendar_date_select (1.15)
    capybara (0.4.1.2)
    capybara-envjs (0.4.0)
    celerity (0.8.9, 0.8.8)
    cheat (1.3.0)
    childprocess (0.1.7)
    chronic (0.3.0)
    churn (0.0.13)
    clipboard (0.9.8)
    coderay (0.9.8)
    colored (1.2)
    columnize (0.3.2)
    configuration (1.2.0)
    crack (0.1.8)
    cucumber (0.10.0)
    cucumber-rails (0.3.2)
    culerity (0.2.15)
    database_cleaner (0.6.4)
    dbi (0.4.5)
    delorean (1.0.0)
    deprecated (2.0.1)
    diff-lcs (1.1.2)
    envjs (0.3.8)
    erubis (2.7.0, 2.6.6)
    every_day_irb (1.0.1)
    factory_girl (1.3.2, 1.2.4)
    fancy_irb (0.6.5)
    fastercsv (1.5.4)
    fattr (2.2.0)
    ffi (1.0.7, 0.6.3)
    flay (1.4.2)
    flog (2.5.1)
    g (1.4.0)
    gherkin (2.3.3)
    ghost (0.2.8)
    gpgme (1.0.8)
    growl (1.0.3)
    haml (3.1.1, 3.0.25)
    hirb (0.4.5, 0.4.0)
    hoptoad_notifier (2.4.8)
    httpclient (2.2.0.2, 2.1.6.1)
    i18n (0.4.1)
    interactive_editor (0.0.8)
    irbtools (1.0.1)
    jasmine (1.0.1.1)
    johnson (2.0.0.pre3)
    json (1.4.6)
    json_pure (1.5.1)
    launchy (0.3.7)
    libnotify (0.1.4)
    linecache (0.43)
    little-plugger (1.1.2)
    logging (1.4.3)
    loquacious (1.6.4)
    main (4.4.0, 4.2.0)
    methodfinder (1.2.3)
    metric_fu (1.5.1)
    mime-types (1.16)
    mocha (0.9.8)
    mustache (0.12.0)
    mysql (2.8.1)
    net-scp (1.0.4)
    net-sftp (2.0.5)
    net-ssh (2.1.3)
    newrelic_rpm (2.9.5)
    no_peeping_toms (1.1.0)
    nokogiri (1.4.4)
    ori (0.1.0)
    polyglot (0.3.1)
    rack (1.2.1, 1.0.1)
    rack-bug (0.3.0)
    rack-mount (0.6.14)
    rack-test (0.5.7)
    rails (2.3.5)
    rails_best_practices (0.8.2)
    rake (0.8.7)
    rb-inotify (0.8.4)
    rcov (0.9.9)
    RedCloth (4.2.7)
    redis (2.1.1)
    redis-namespace (0.8.0)
    reek (1.2.8)
    resque (1.10.0)
    rjb (1.2.6)
    roodi (2.1.0)
    rspactor (0.7.0.beta.7)
    rspec (1.3.0)
    rspec-expectations (2.5.0)
    rspec-mocks (2.5.0)
    rspec-rails (1.3.2)
    ruby-debug (0.10.4)
    ruby-debug-base (0.10.4)
    ruby-growl (3.0)
    ruby-progressbar (0.0.9)
    ruby2ruby (1.2.5)
    ruby_parser (2.0.6)
    rubyzip (0.9.4)
    rufus-tokyo (1.0.7)
    rvm_loader (1.0.0)
    Saikuro (1.1.0)
    selenium-client (1.2.18)
    selenium-rc (2.3.2)
    selenium-webdriver (0.1.3)
    sexp_processor (3.0.5)
    sham_rack (1.3.3)
    sinatra (1.2.3, 1.2.1, 1.0)
    sketches (0.1.1)
    soap4r (1.5.8)
    spoon (0.0.1)
    stackdeck (0.2.0)
    sys-uname (0.8.5)
    SystemTimer (1.2.2)
    term-ansicolor (1.0.5)
    test-spec (0.10.0)
    thor (0.14.6)
    thoughtbot-factory_girl (1.2.2)
    tilt (1.2.2)
    treetop (1.4.9)
    trollop (1.16.2)
    tyrantmanager (1.6.0)
    tzinfo (0.3.24)
    unicode-display_width (0.1.1)
    vegas (0.1.8)
    webmock (1.6.2)
    wirb (0.2.6)
    wirble (0.1.3)
    xpath (0.1.4, 0.1.3)
    yajl-ruby (0.8.1)
    zucker (10)
    EOL
  end
end

module LtGems
  extend self
  def gem_list
    list =<<-EOL
    abstract (1.0.0)
    actionmailer (2.3.5)
    actionpack (3.0.4, 2.3.5)
    activemodel (3.0.4)
    activerecord (3.0.4, 2.3.5)
    activeresource (2.3.5)
    activesupport (3.0.4, 3.0.0, 2.3.5)
    arel (2.0.8)
    arrayfields (4.7.4)
    awesome_print (0.3.2, 0.2.1)
    builder (3.0.0, 2.1.2)
    bundler (1.0.10, 1.0.0)
    capybara (0.4.1.2)
    capybara-envjs (0.4.0)
    celerity (0.8.8, 0.8.7)
    cgi_multipart_eof_fix (2.5.0)
    childprocess (0.1.7, 0.1.6)
    chronic (0.3.0, 0.2.3)
    churn (0.0.13, 0.0.12)
    colored (1.2)
    columnize (0.3.2, 0.3.1)
    configuration (1.2.0)
    crack (0.1.8)
    cucumber (0.10.0)
    cucumber-rails (0.3.2)
    culerity (0.2.15)
    daemons (1.1.0)
    database_cleaner (0.6.5, 0.5.0)
    delorean (1.0.0, 0.2.1)
    diff-lcs (1.1.2)
    envjs (0.3.8)
    erubis (2.6.6)
    factory_girl (1.3.3, 1.3.2)
    fastercsv (1.5.4, 1.5.3)
    fastthread (1.0.7)
    fattr (2.2.0, 2.1.0)
    ffi (0.6.3)
    flay (1.4.2, 1.4.1)
    flog (2.5.1, 2.5.0)
    gem_plugin (0.2.3)
    gherkin (2.3.4, 2.3.3)
    ghost (0.2.8)
    gpgme (1.0.8)
    growl (1.0.3)
    haml (3.0.25)
    hirb (0.4.0, 0.3.4)
    hoe (2.6.2)
    httpclient (2.1.6.1, 2.1.5.2)
    hydra (0.16.2)
    i18n (0.5.0)
    jasmine (1.0.1.1)
    johnson (2.0.0.pre3)
    json (1.4.6)
    json_pure (1.5.1, 1.4.6)
    launchy (0.3.7)
    libnotify (0.1.4)
    linecache (0.43)
    little-plugger (1.1.2)
    logging (1.4.3)
    loquacious (1.6.4)
    main (4.4.0, 4.2.0)
    metric_fu (1.5.1)
    mime-types (1.16)
    mocha (0.9.8)
    mongrel (1.1.5)
    mysql (2.8.1)
    nest (1.1.0)
    net-scp (1.0.4)
    net-sftp (2.0.5)
    net-ssh (2.1.3, 2.1.0)
    newrelic_rpm (2.13.4)
    no_peeping_toms (1.1.0)
    nokogiri (1.4.4)
    ohm (0.1.3)
    ohm-contrib (0.1.1)
    rack-bug (0.3.0)
    rack-mount (0.6.13)
    rack-test (0.5.7)
    rails (2.3.5)
    rails_best_practices (0.7.1, 0.6.6)
    railties (3.0.4)
    rake (0.8.7)
    rb-inotify (0.8.4)
    rcov (0.9.9)
    RedCloth (4.2.5)
    redis (2.2.0)
    redis-namespace (0.10.0, 0.8.0)
    reek (1.2.8)
    resque (1.10.0)
    rjb (1.3.4, 1.2.6)
    roodi (2.1.0)
    rspactor (0.7.0.beta.7)
    rspec (1.3.0)
    rspec-core (2.5.1, 2.1.0)
    rspec-expectations (2.5.0, 2.1.0)
    rspec-mocks (2.5.0, 2.1.0)
    rspec-rails (1.3.2)
    ruby-debug (0.10.4)
    ruby-debug-base (0.10.4)
    ruby2ruby (1.2.5)
    ruby_parser (2.0.6, 2.0.5)
    rubyzip (0.9.4)
    rufus-tokyo (1.0.7)
    Saikuro (1.1.0)
    selenium-client (1.2.18)
    selenium-rc (2.2.4)
    selenium-webdriver (0.1.3, 0.1.2)
    sexp_processor (3.0.5)
    sham_rack (1.3.3)
    sinatra (1.1.2, 1.0)
    soap4r (1.5.8)
    stackdeck (0.2.0)
    sys-uname (0.8.5)
    SystemTimer (1.2.2)
    term-ansicolor (1.0.5)
    test-spec (0.10.0)
    thor (0.14.6)
    tilt (1.2.2)
    trollop (1.16.2)
    tyrantmanager (1.6.0)
    tzinfo (0.3.24)
    webmock (1.6.2)
    xpath (0.1.3)
    yajl-ruby (0.7.7)
    ZenTest (4.4.0)
    EOL
  end
end

class GemInstallCommander
  include ChemistryVendoredGemsPlus
end

gems = nil

# lt:
# jt_gems = JtGems.gem_list
# lt_gems = LtGems.gem_list
# lt_gems.split("\n") - jt_gems.split("\n")
# exit
# HAL:
#gems = InstalledGems.gem_list

puts
to_uninstall = GemInstallCommander.new(gems).gen_uninstall_cmds
if !to_uninstall.empty? 
  puts "please uninstall the following gems:"
  puts to_uninstall
else
  puts "you have no gems to uninstall"
end
puts

puts
to_install = GemInstallCommander.new(gems).gen_install_cmds
if !to_install.empty? 
  puts "please install the following gems:"
  puts to_install
else
  puts "you have no gems to install"
end
puts
