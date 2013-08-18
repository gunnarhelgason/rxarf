# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rxarf/version'

Gem::Specification.new do |gem|
  gem.name          = "rxarf"
  gem.version       = XARF::VERSION
  gem.authors       = ["Gunnar Helgason"]
  gem.email         = ["gunnar.helgason@gmail.com"]
  gem.summary       = "Create, read and validate X-ARF reports"
  gem.homepage      = "https://github.com/gunnarhelgason/rxarf"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "minitest"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "rake"

  gem.add_runtime_dependency "json"
  gem.add_runtime_dependency "json-schema"
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "safe_yaml"
end
