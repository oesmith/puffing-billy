# Deprecated
require 'capybara/rspec'
require 'billy/browsers/capybara'
require 'billy/init/rspec'

Billy::Browsers::Capybara.register_drivers

warn "[DEPRECATION] `require 'billy/rspec'` is deprecated. Please use `require 'billy/capybara/rspec'` instead."
