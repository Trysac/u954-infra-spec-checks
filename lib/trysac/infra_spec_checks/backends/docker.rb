# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    module Backends
      # Runs probes inside a container with docker exec; every value is escaped with Shellwords.escape.
      class Docker
        # @return [String] the container name
        attr_reader :container

        # @param container [String] a validated container name or id
        # @param runner [#call] the process runner
        # @raise [Error] :invalid_name for a bad container name
        def initialize(container, runner: Runner::Open3Runner.new)
          @container = Validate.container(container)
          @runner = runner
        end

        # @param argv [Array<String>] program and arguments
        # @param timeout [Numeric] seconds
        # @return [Array(String, String, Integer)] stdout, stderr, status
        def execute(argv, timeout: DEFAULT_TIMEOUT)
          script = Validate.arguments(argv).map { |part| Shellwords.escape(part) }.join(" ")
          @runner.call(["docker", "exec", container, "sh", "-c", script], timeout: timeout)
        end
      end
    end
  end
end
