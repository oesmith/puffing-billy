# encoding: utf-8
# frozen_string_literal: true

require 'fileutils'

module Billy
  # This class is dedicated to the generation of a certificate chain in the
  # PEM format. Fortunately we just have to concatinate the given certificates
  # in the given order and write them to temporary file which will last until
  # the current process terminates.
  #
  # We do not have to generate a certificate chain to make puffing billy work
  # on modern browser like Chrome 59+ or Firefox 55+, but its good to ship it
  # anyways. This mimics the behaviour of the mighty mitmproxy.
  class CertificateChain
    attr_reader :certificates, :domain

    # Just pass all certificates into the new instance. We use the variadic
    # argument feature here to ease the usage and improve the readability.
    #
    # Example:
    #
    #   certs_chain_file = Billy::CertificateChain.new('localhost',
    #                                                  cert1,
    #                                                  cert2, ..).file
    def initialize(domain, *certs)
      @domain = domain
      @certificates = [certs].flatten
    end

    # Write out the certificates chain file and pass the path back. This will
    # produce a temporary file which will be remove after the current process
    # terminates.
    def file
      path = File.join(Billy.config.certs_path, "chain-#{domain}.pem")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, certificates.map { |cert| cert.to_pem }.join)
      path
    end
  end
end
