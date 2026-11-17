# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    module Backends
      # Answers probes from a table: argv array to [stdout, stderr, status] or :timeout.
      class Fake
        # @param responses [Hash{Array<String> => Array, Symbol}] the canned responses
        def initialize(responses)
          raise Error.new(:invalid_checks, "responses must be a Hash") unless responses.is_a?(Hash)

          @responses = responses.dup.freeze
        end

        # @param argv [Array<String>] program and arguments
        # @return [Array(String, String, Integer)] the canned answer, or an empty one with status 127
        # @raise [CommandTimeout] when the response is :timeout
        def execute(argv, **)
          response = @responses[argv]
          return ["", "", 127] if response.nil?
          raise CommandTimeout if response == :timeout

          response
        end
      end
    end
  end
end
