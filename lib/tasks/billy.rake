require 'addressable/uri'

namespace :cache do

  desc 'Print out all cache file information'
  task :print_all do
    cache_array = load_cache

    sort_cache(cache_array).each do |cache|
      print_cache_details(cache)
    end
  end

  desc 'Print out specific cache file information'
  task :print_details, :sha do |t, args|
    raise "Missing sha; usage: rake cache:print_details['<sha>']" unless args[:sha]
    cache_array = load_cache(Billy.config.cache_path, '*'+args[:sha]+'*.yml')

    sort_cache(cache_array).each do |cache|
      print_cache_details(cache)
    end
  end

  desc 'Find specific cache files by URL'
  task :find_by_url, :api_path do |t, args|
    raise "Missing api path; usage: rake cache:find_by_url['<api_path>']" unless args[:api_path]
    cache_array = load_cache
    filtered_cache_array = cache_array.select {|f| f[:url_path].include?(args[:api_path]) }

    sort_cache(filtered_cache_array).each do |cache|
      print_cache_details(cache)
    end
  end

  desc 'Find specific cache files by scope'
  task :find_by_scope, :scope do |t, args|
    raise "Missing scope; usage: rake cache:find_by_scope['<scope>']" unless args[:scope]
    cache_array = load_cache
    filtered_cache_array = cache_array.select {|f| f[:scope] && f[:scope].include?(args[:scope]) }

    sort_cache(filtered_cache_array).each do |cache|
      print_cache_details(cache)
    end
  end

  desc 'Find cache files with non-successful status codes'
  task :find_non_successful do
    cache_array = load_cache
    filtered_cache_array = cache_array.select {|f| !(200..299).include?(f[:status]) }

    sort_cache(filtered_cache_array).each do |cache|
      print_cache_details(cache)
    end
  end

  def load_cache(cache_directory = Billy.config.cache_path, file_pattern = '*.yml')
    cache_path  = Rails.root.join(cache_directory)
    cache_array = []

    Dir.glob(cache_path+file_pattern) do |filename|
      data = load_cache_file(filename)
      url = Addressable::URI.parse(data[:url])
      data[:url_path] = "#{url.path}#{url.query ? '?'+url.query : ''}#{url.fragment ? '#'+url.fragment : ''}"
      data[:filename] = filename.gsub(Rails.root.to_s+'/','')
      cache_array << data
    end
    cache_array
  end

  def load_cache_file(filename)
    YAML.load(File.open(filename))
  rescue ArgumentError => e
    puts "Could not parse YAML: #{e.message}"
  end

  def print_cache_details(cache)
    puts "   Scope: #{cache[:scope]}" if cache[:scope]
    puts "     URL: #{cache[:url]}"
    puts "    Body: #{cache[:body]}" if cache[:method] == 'post'
    puts " Details: Request method '#{cache[:method]}' returned response status code: '#{cache[:status]}'"
    puts "Filename: #{cache[:filename]}"
    puts "\n\n"
  end

  def sort_cache(cache, key = :url_path)
    cache.sort_by { |hsh| hsh[key] }
  end

end
