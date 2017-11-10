# encoding: utf-8
# frozen_string_literal: true

require 'openssl'
require 'fileutils'

module Billy
  # This class is dedicated to the generation of a request certifcate for a
  # given domain name. We have to generate for each handled connection a new
  # request certifcate, due to the fact that each request has probably a
  # different domain name which will be proxied. So we can't know of future
  # domain name we could include in the list of subject alternative names
  # which is required by modern browsers. (Chrome 58+)
  #
  # We use our generated certifcate authority to sign any request certifcate,
  # so a client can be prepared to trust us before a possible test scenario
  # starts.
  #
  # This behaviour and functionality mimics the mighty mitmproxy and it will
  # enable the usage of Chrome Headless at a time where no ssl issue ignoring
  # works. And its even secure at testing level.
  class Certificate
    include Billy::CertificateHelpers

    attr_reader :key, :cert, :domain

    # To generate a new request certifcate just pass the domain in and you
    # are ready to go.
    #
    # Example:
    #
    #   cert = Billy::Certificate.new('localhost')
    #   [cert.cert_file, cert.key_file]
    def initialize(domain)
      @domain = domain
      @key = OpenSSL::PKey::RSA.new(2048)
      @cert = generate
    end

    # Write out the private key to file (PEM format) and give back the
    # file path.
    def key_file
      write_file("request-#{domain}.key", key.to_pem)
    end

    # Write out the certifcate to file (PEM format) and give back the
    # file path.
    def cert_file
      write_file("request-#{domain}.crt", cert.to_pem)
    end

    private

    # Defines a static list of available extensions on the certificate.
    def extensions
      # ln_sn, value, critical
      [['subjectAltName', "DNS:#{domain}", false]]
    end

    # Generate a fresh new certificate for the configured domain.
    def generate
      cert = OpenSSL::X509::Certificate.new
      configure(cert)
      add_extensions(cert)
      cert.sign(Billy.certificate_authority.key, OpenSSL::Digest::SHA256.new)
    end

    # Generate a new certificate signing request (CSR) which will be picked
    # up by the certificate subject and public key.
    def signing_request
      req = OpenSSL::X509::Request.new
      req.public_key = key.public_key
      req.subject = OpenSSL::X509::Name.new([['CN', domain]])
      req.sign(key, OpenSSL::Digest::SHA256.new)
    end

    # Setup all relevant properties of the given certificate to produce
    # a valid and useable certificate.
    def configure(cert)
      req = signing_request
      cert.issuer = Billy.certificate_authority.cert.subject
      cert.not_before = days_ago(2)
      cert.not_after = days_from_now(2)
      cert.public_key = req.public_key
      cert.serial = serial
      cert.subject = req.subject
      cert.version = 2
    end

    # Add all extensions (defined by the +extensions+ method) to the given
    # certificate.
    def add_extensions(cert)
      factory = OpenSSL::X509::ExtensionFactory.new
      factory.issuer_certificate = Billy.certificate_authority.cert
      factory.subject_certificate = cert
      extensions.each do |ln_sn, value, critical|
        cert.add_extension(factory.create_extension(ln_sn, value, critical))
      end
    end
  end
end
