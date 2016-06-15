# Deprecated
require 'capybara/rspec'
require 'billy/capybara/capybara'
require 'billy/init/rspec'

Billy.register_drivers_capybara

warn "[DEPRECATION] `require 'billy/rspec'` is deprecated. Please use `require 'billy/capybara/rspec'` instead."
