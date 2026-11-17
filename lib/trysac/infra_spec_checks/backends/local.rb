# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    module Backends
      # Runs probes on this host with argv arrays.
      class Local
        # @param runner [#call] the process runner
        def initialize(runner: Runner::Open3Runner.new)
          @runner = runner
        end

        # @param argv [Array<String>] program and arguments
        # @param timeout [Numeric] seconds
        # @return [Array(String, String, Integer)] stdout, stderr, status
        def execute(argv, timeout: DEFAULT_TIMEOUT)
          @runner.call(Validate.arguments(argv), timeout: timeout)
        end
      end
    end
  end
end
