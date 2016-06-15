# Deprecated
require 'capybara/cucumber'
require 'billy/capybara/capybara'
require 'billy/init/cucumber'

Billy.register_drivers_capybara

warn "[DEPRECATION] `require 'billy/cucumber'` is deprecated. Please use `require 'billy/capybara/cucumber'` instead."
