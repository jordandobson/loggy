# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{loggy}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jordan Dobson"]
  s.date = %q{2009-05-09}
  s.default_executable = %q{loggy}
  s.description = %q{Apache Log DNS Lookup command line tool}
  s.email = ["jordan.dobson@madebysquad.com"]
  s.executables = ["loggy"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/loggy", "lib/loggy.rb", "lib/cache.yml", "test/test_loggy.rb", "test/test_cache.yml", "test/test_log.log", "test/test_log_empty.log", "test/log/apache_log.log"]
  s.homepage = %q{http://github.com/jordandobson/loggy/tree/master}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{loggy}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Apache Log DNS Lookup command line tool}
  s.test_files = ["test/test_loggy.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.12.2"])
    else
      s.add_dependency(%q<hoe>, [">= 1.12.2"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.12.2"])
  end
end