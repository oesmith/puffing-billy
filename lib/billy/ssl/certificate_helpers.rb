# encoding: utf-8
# frozen_string_literal: true

require 'openssl'
require 'fileutils'

module Billy
  # A set of common certificate helper methods.
  module CertificateHelpers

    # Give back the date from now plus given days.
    def days_from_now(days)
      Time.now + (days * 24 * 60 * 60)
    end

    # Give back the date from now minus given days.
    def days_ago(days)
      Time.now - (days * 24 * 60 * 60)
    end

    # Generate a random serial number for a certificate.
    def serial
      rand(1_000_000..100_000_000_000)
    end

    # Create/Overwrite a new file with the given name
    # and ensure the location is safely created. Pass
    # back the resulting path.
    def write_file(name, contents)
      path = File.join(Billy.config.certs_path, name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, contents)
      path
    end
  end
end
