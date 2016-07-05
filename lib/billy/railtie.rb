module Billy
  class Railtie < Rails::Railtie
    railtie_name 'billy'

    rake_tasks do
      load 'tasks/billy.rake'
    end
  end
end
