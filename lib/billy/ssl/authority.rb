# encoding: utf-8
# frozen_string_literal: true

require 'openssl'
require 'fileutils'

module Billy
  # This class is dedicated to the generation of a brand new certificate
  # authority which can be picked up by a browser to verify and secure any
  # communication with puffing billy. This authority certificate will be
  # generated once on runtime and will sign each request certificate. So
  # we do not have to deal with outdated certificates or stuff like that.
  #
  # The resulting certificate authority is at its bare minimum to keep
  # things simple and snappy. We do not handle a certificate revoke list
  # (CRL) nor any other special key handling, even if we enable these
  # extensions. It's just a mimic of the mighty mitmproxy certificate
  # authority file.
  class Authority
    attr_reader :key, :cert

    # The authority generation does not require any arguments from outside
    # of this class definition. We just generate the certificate and thats
    # it.
    #
    # Example:
    #
    #   ca = Billy::Authority.new
    #   [ca.cert_file, ca.key_file]
    def initialize
      @key = OpenSSL::PKey::RSA.new(2048)
      @cert = generate
    end

    # Write out the private key to file (PEM format) and give back the
    # file path. This will produce a temporary file which will be remove
    # after the current process terminates.
    def key_file
      path = File.join(Billy.config.certs_path, 'ca.key')
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, key.to_pem)
      path
    end

    # Write out the certifcate to file (PEM format) and give back the
    # file path. This will produce a temporary file which will be remove
    # after the current process terminates.
    def cert_file
      path = File.join(Billy.config.certs_path, 'ca.crt')
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, cert.to_pem)
      path
    end

    private

    # Defines a static list of available extensions on the certificate.
    def extensions
      [
        # ln_sn, value, critical
        ['basicConstraints', 'CA:TRUE', true],
        ['keyUsage', 'keyCertSign, cRLSign', true],
        ['subjectKeyIdentifier', 'hash', false],
        ['authorityKeyIdentifier', 'keyid:always', false]
      ]
    end

    # Give back the static subject name of the certificate.
    def name
      ['CN=Puffing Billy', 'O=Puffing Billy'].join('/')
                                             .prepend('/')
                                             .concat('/')
    end

    # Give back an appropriate date for the beginning of this
    # certificate life. We give back now 2 days ago.
    def valid_from
      Time.now - (2 * 24 * 60 * 60)
    end

    # Give back an appropriate date for the end of this certificate life.
    # We give back now in 2 days.
    def valid_to
      Time.now + (2 * 24 * 60 * 60)
    end

    # Generate a random serial number for the certificate.
    def serial
      Time.now.to_i + rand(100_000_000_000)
    end

    # Generate a fresh new certificate for the configured domain.
    def generate
      cert = OpenSSL::X509::Certificate.new
      configure(cert)
      add_extensions(cert)
      cert.sign(key, OpenSSL::Digest::SHA256.new)
    end

    # Setup all relevant properties of the given certificate to produce
    # a valid and useable certificate.
    def configure(cert)
      cert.version = 2
      cert.serial = serial
      cert.subject = OpenSSL::X509::Name.parse(name)
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = valid_from
      cert.not_after = valid_to
    end

    # Add all extensions (defined by the +extensions+ method) to the given
    # certificate.
    def add_extensions(cert)
      factory = OpenSSL::X509::ExtensionFactory.new
      factory.subject_certificate = cert
      factory.issuer_certificate = cert
      extensions.each do |ln_sn, value, critical|
        cert.add_extension(factory.create_extension(ln_sn, value, critical))
      end
    end
  end
end
