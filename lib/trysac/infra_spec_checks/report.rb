# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # The results of a suite run, in check order.
    class Report
      # @return [Array<Result>] the results
      attr_reader :results

      # @param results [Array<Result>] the results
      def initialize(results)
        @results = results.dup.freeze
      end

      # @return [Boolean] true when nothing failed and nothing errored
      def passed? = failed.zero? && errors.zero?

      # @return [Integer] number of passes
      def passed = count("pass")

      # @return [Integer] number of failures
      def failed = count("fail")

      # @return [Integer] number of errors
      def errors = count("error")

      # @return [Hash] counts and one hash per result
      def to_h
        { "passed" => passed, "failed" => failed, "errors" => errors, "results" => results.map(&:to_h) }
      end

      # @return [String] one line per result
      def to_text = results.map(&:to_text).join("\n")

      private

      def count(status) = results.count { |r| r.status == status }
    end
  end
end
