# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Base class of the check objects.
    class Check
      # Runs the check; library errors become error results so other checks still run.
      #
      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def run(backend)
        evaluate(backend)
      rescue Error => e
        Result.error(subject, e.code)
      end
    end
  end
end
