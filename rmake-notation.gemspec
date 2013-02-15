# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rmake-notation/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["akasata", "Rmake Co., Ltd."]
  gem.email         = ["akasata@rmake.net"]
  gem.description   = %q{A simple wiki engine for Rmake. }
  gem.summary       = %q{A simple wiki engine}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rmake-notation"
  gem.require_paths = ["lib"]
  gem.version       = Rmake::Notation::VERSION
  
  gem.add_development_dependency('rspec')
end

