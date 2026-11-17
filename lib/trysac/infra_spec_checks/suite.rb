# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # An ordered list of checks.
    class Suite
      # Largest checks document in bytes.
      MAX_BYTES = 1_048_576
      # Most checks in a suite.
      MAX_CHECKS = 1_000
      # Allowed keys per check kind.
      KEYS = {
        "port" => %w[port address], "package" => %w[package version], "service" => %w[service],
        "file" => %w[file mode owner group], "command" => %w[command exit_status]
      }.freeze

      # @return [Array<Check>] the checks
      attr_reader :checks

      # Builds a suite from a JSON array of check objects.
      #
      # @param text [String] the JSON document
      # @return [Suite] the suite
      # @raise [Error] :input_too_large or :invalid_checks, or the code of an invalid value
      def self.from_json(text)
        raise Error.new(:invalid_checks, "input must be a String") unless text.is_a?(String)
        raise Error.new(:input_too_large, "checks input exceeds #{MAX_BYTES} bytes") if text.bytesize > MAX_BYTES

        new(entries(parse(text)).map { |entry| build(entry) })
      end

      # @api private
      def self.entries(data)
        raise Error.new(:invalid_checks, "checks must be a JSON array") unless data.is_a?(Array)
        raise Error.new(:input_too_large, "more than #{MAX_CHECKS} checks") if data.size > MAX_CHECKS

        data
      end

      # @api private
      def self.parse(text)
        JSON.parse(text, max_nesting: 8)
      rescue JSON::ParserError, EncodingError
        raise Error.new(:invalid_checks, "invalid JSON")
      end

      # @api private
      def self.check_kind(entry)
        raise Error.new(:invalid_checks, "each check must be an object") unless entry.is_a?(Hash)

        kinds = KEYS.keys & entry.keys
        raise Error.new(:invalid_checks, "each check needs exactly one kind key") unless kinds.size == 1

        kind = kinds.first
        raise Error.new(:invalid_checks, "unknown key in a #{kind} check") unless (entry.keys - KEYS.fetch(kind)).empty?

        kind
      end

      # @api private
      def self.build(entry)
        case check_kind(entry)
        when "port" then PortCheck.new(entry["port"]).listening(address: entry["address"])
        when "package" then PackageCheck.new(entry["package"]).installed(version: entry["version"])
        when "service" then ServiceCheck.new(entry["service"]).running
        when "file" then build_file(entry)
        else build_command(entry)
        end
      end

      # @api private
      def self.build_file(entry)
        check = FileCheck.new(entry["file"]).exists
        check.mode(entry["mode"]) if entry.key?("mode")
        check.owner(entry["owner"]) if entry.key?("owner")
        check.group(entry["group"]) if entry.key?("group")
        check
      end

      # @api private
      def self.build_command(entry)
        argv = entry["command"]
        raise Error.new(:invalid_checks, "command must be an array") unless argv.is_a?(Array)

        check = CommandCheck.new(*argv)
        check.exit_status(entry["exit_status"]) if entry.key?("exit_status")
        check
      end

      private_class_method :parse, :entries, :check_kind, :build, :build_file, :build_command

      # @param checks [Array<Check>] the checks
      # @raise [Error] :input_too_large above 1000 checks
      def initialize(checks)
        raise Error.new(:input_too_large, "more than #{MAX_CHECKS} checks") if checks.size > MAX_CHECKS

        @checks = checks.dup.freeze
      end

      # Runs every check; one failing or timing-out check never stops the others.
      #
      # @param backend [#execute] the backend
      # @return [Report] the report
      def run(backend)
        Report.new(checks.map { |check| check.run(backend) })
      end
    end
  end
end
