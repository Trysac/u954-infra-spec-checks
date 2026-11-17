# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Command-line entry point.
    module CLI
      # Usage text.
      USAGE = "usage: infra-spec-checks [--local | --docker CONTAINER] [--json] CHECKS.json"

      # Runs a checks file.
      #
      # @param argv [Array<String>] the arguments
      # @param stdout [IO] the output stream
      # @param stderr [IO] the error stream
      # @param runner [#call] the process runner
      # @return [Integer] 0 all passed, 1 a check failed or errored, 2 usage, IO or parse error
      def self.run(argv, stdout: $stdout, stderr: $stderr, runner: Runner::Open3Runner.new)
        report, json = execute(argv, runner)
        stdout.puts(json ? JSON.generate(report.to_h) : report.to_text)
        report.passed? ? 0 : 1
      rescue Error => e
        fail_with(stderr, "#{e.code}: #{e.message}")
      rescue SystemCallError => e
        fail_with(stderr, "io: #{Error.clip(e.message)}")
      end

      # @api private
      def self.execute(argv, runner)
        options = parse(argv)
        suite = Suite.from_json(read(options.fetch(:file)))
        [suite.run(backend(options, runner)), options.fetch(:json)]
      end

      # @api private
      def self.fail_with(stderr, text)
        stderr.puts("error: #{text}")
        2
      end

      # @api private
      def self.parse(argv)
        options = { json: false, docker: nil, file: nil }
        args = argv.dup
        apply(options, args.shift, args) until args.empty?
        options[:file] || usage
        options
      end

      # @api private
      def self.apply(options, arg, args)
        case arg
        when "--json" then options[:json] = true
        when "--local" then options[:docker] = nil
        when "--docker" then options[:docker] = args.shift || usage
        when /\A-/ then usage
        else options[:file] = options[:file] ? usage : arg
        end
      end

      # @api private
      def self.usage = raise(Error.new(:usage, USAGE))

      # @api private
      def self.read(path)
        data = File.open(path, "rb") { |file| file.read(Suite::MAX_BYTES + 1) } || +""
        if data.bytesize > Suite::MAX_BYTES
          raise Error.new(:input_too_large, "checks file exceeds #{Suite::MAX_BYTES} bytes")
        end

        data.force_encoding(Encoding::UTF_8)
      end

      # @api private
      def self.backend(options, runner)
        container = options[:docker]
        container ? Backends::Docker.new(container, runner: runner) : Backends::Local.new(runner: runner)
      end

      private_class_method :execute, :fail_with, :parse, :apply, :usage, :read, :backend
    end
  end
end
