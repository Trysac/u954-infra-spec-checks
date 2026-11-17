# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Validators for every value that can reach a command line.
    module Validate
      # Package, service and user names.
      NAME = /\A[A-Za-z0-9][A-Za-z0-9._+:@-]{0,127}\z/
      # Package versions.
      VERSION = /\A[A-Za-z0-9][A-Za-z0-9._+:~-]{0,127}\z/
      # Container names.
      CONTAINER = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
      # Listening addresses.
      ADDRESS = /\A[0-9A-Fa-f:.]{2,45}\z/
      # Octal file modes.
      MODE = /\A[0-7]{3,4}\z/
      # Longest path in bytes.
      MAX_PATH = 4096
      # Most elements of one argv.
      MAX_ARGUMENTS = 256

      # @param value [Object] the candidate port
      # @return [Integer] the port
      # @raise [Error] :invalid_port outside 1..65535
      def self.port(value)
        return value if value.is_a?(Integer) && value.between?(1, 65_535)

        raise Error.new(:invalid_port, "port must be an integer between 1 and 65535")
      end

      # @param value [Object] the candidate name
      # @return [String] the name
      # @raise [Error] :invalid_name
      def self.name(value) = match(value, NAME, :invalid_name, "name")

      # @param value [Object] the candidate version
      # @return [String] the version
      # @raise [Error] :invalid_name
      def self.version(value) = match(value, VERSION, :invalid_name, "version")

      # @param value [Object] the candidate container name
      # @return [String] the container name
      # @raise [Error] :invalid_name
      def self.container(value) = match(value, CONTAINER, :invalid_name, "container name")

      # @param value [Object] the candidate address
      # @return [String] the address
      # @raise [Error] :invalid_checks
      def self.address(value) = match(value, ADDRESS, :invalid_checks, "address")

      # @param value [Object] the candidate mode
      # @return [String] the mode padded to four octal digits
      # @raise [Error] :invalid_mode
      def self.mode(value) = match(value, MODE, :invalid_mode, "mode").rjust(4, "0")

      # @param value [Object] the candidate path
      # @return [String] the absolute path
      # @raise [Error] :invalid_path
      def self.path(value)
        ok = text?(value) && value.bytesize.between?(1, MAX_PATH) && value.start_with?("/") &&
             !value.match?(/[\0\n]/)
        raise Error.new(:invalid_path, "invalid absolute path") unless ok

        value
      end

      # @param value [Object] a program name or absolute path
      # @return [String] the program
      # @raise [Error] :invalid_name or :invalid_path
      def self.program(value)
        value.is_a?(String) && value.start_with?("/") ? path(value) : name(value)
      end

      # @param list [Object] an argv candidate
      # @return [Array<String>] the argv
      # @raise [Error] :invalid_checks
      def self.arguments(list)
        ok = list.is_a?(Array) && list.size.between?(1, MAX_ARGUMENTS) &&
             list.all? { |a| text?(a) && a.bytesize <= MAX_PATH && !a.include?("\0") }
        raise Error.new(:invalid_checks, "invalid argument list") unless ok

        list
      end

      # @api private
      def self.match(value, regex, code, label)
        return value if text?(value) && value.match?(regex)

        raise Error.new(code, "invalid #{label}")
      end

      # @api private
      def self.text?(value) = value.is_a?(String) && value.valid_encoding?

      private_class_method :match, :text?
    end
  end
end
