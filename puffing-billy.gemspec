# -*- encoding: utf-8 -*-
require File.expand_path('../lib/billy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Olly Smith']
  gem.email         = ['olly.smith@gmail.com']
  gem.description   = 'A stubbing proxy server for ruby. Connect it to your browser in integration tests to fake interactions with remote HTTP(S) servers.'
  gem.summary       = 'Easy request stubs for browser tests.'
  gem.homepage      = 'https://github.com/oesmith/puffing-billy'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'puffing-billy'
  gem.require_paths = ['lib']
  gem.version       = Billy::VERSION

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'thin'
  gem.add_development_dependency 'faraday'
  gem.add_development_dependency 'poltergeist'
  gem.add_development_dependency 'selenium-webdriver'
  gem.add_development_dependency 'capybara'
  gem.add_development_dependency 'capybara-webkit', '~> 1.0'
  gem.add_development_dependency 'rack'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'rb-inotify'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'cucumber'
  gem.add_runtime_dependency 'addressable'
  gem.add_runtime_dependency 'eventmachine', '~> 1.0.4'
  gem.add_runtime_dependency 'em-synchrony'
  # Pinning to 1.1.3 due to https://github.com/oesmith/puffing-billy/issues/164
  gem.add_runtime_dependency 'em-http-request', '= 1.1.3'
  gem.add_runtime_dependency 'eventmachine_httpserver'
  gem.add_runtime_dependency 'http_parser.rb', '~> 0.6.0'
  gem.add_runtime_dependency 'multi_json'
end
