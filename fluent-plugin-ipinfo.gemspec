$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-ipinfo"
  s.version     = "1.1.0"
  s.license     = "Apache-2.0"
  s.authors     = ["Ahmed Abdelkafi"]
  s.email       = ["abdelkafiahmed@gmail.com"]
  s.homepage    = "https://github.com/Razerban/fluent-plugin-ipinfo"
  s.summary     = %q{Fluentd filter plugin. It fetches geographical location data of an IP address.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'fluentd', '>= 0.14.2', '< 2'
  s.add_runtime_dependency 'IPinfo', '~> 1.0', '>= 1.0.1'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'
    s.add_development_dependency 'test-unit', '~> 3.5.5'
  end
end