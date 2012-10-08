# -*- encoding: utf-8 -*-
require File.expand_path('../lib/billy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Olly Smith"]
  gem.email         = ["olly.smith@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "puffing-billy"
  gem.require_paths = ["lib"]
  gem.version       = Billy::VERSION

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "thin"
  gem.add_development_dependency "faraday"
  gem.add_runtime_dependency "eventmachine"
  gem.add_runtime_dependency "em-http-request"
  gem.add_runtime_dependency "eventmachine_httpserver"
  gem.add_runtime_dependency "http_parser.rb"
end
