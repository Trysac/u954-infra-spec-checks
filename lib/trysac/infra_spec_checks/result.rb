# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # The outcome of one check: pass, fail or error.
    class Result
      # @return [String] "pass", "fail" or "error"
      attr_reader :status
      # @return [String] the subject, such as "port 80"
      attr_reader :subject
      # @return [String, nil] the failed attribute
      attr_reader :attribute
      # @return [String, nil] the expected value
      attr_reader :expected
      # @return [String, nil] the actual value
      attr_reader :actual
      # @return [String, nil] a human message
      attr_reader :message
      # @return [String, nil] the error code
      attr_reader :code

      # @param subject [String] the subject
      # @return [Result] a passing result
      def self.success(subject) = new(status: "pass", subject: subject)

      # @param subject [String] the subject
      # @param attribute [String] the attribute that differs
      # @param expected [#to_s] the expected value
      # @param actual [#to_s] the actual value
      # @param message [String, nil] an optional message
      # @return [Result] a failing result
      def self.failure(subject, attribute, expected, actual, message = nil)
        new(status: "fail", subject: subject, attribute: attribute, expected: expected, actual: actual,
            message: message)
      end

      # @param subject [String] the subject
      # @param code [Symbol, String] the error code
      # @return [Result] an error result
      def self.error(subject, code) = new(status: "error", subject: subject, code: code.to_s)

      # Makes a value safe for reports: replaces control characters with "?" and clips its length.
      #
      # @param value [#to_s, nil] the value to clean
      # @return [String, nil] the cleaned, clipped text, or nil when the value is nil
      def self.clean(value) = value.nil? ? nil : Error.clip(value.to_s.gsub(/[[:cntrl:]]/, "?"))

      # @param status [String] the status
      # @param subject [String] the subject
      # @param fields [Hash{Symbol => Object}] the optional fields of the result
      # @option fields [String, nil] :attribute the attribute
      # @option fields [#to_s, nil] :expected the expected value
      # @option fields [#to_s, nil] :actual the actual value
      # @option fields [String, nil] :message the message
      # @option fields [String, nil] :code the error code
      def initialize(status:, subject:, **fields)
        @status = status
        @subject = self.class.clean(subject)
        @attribute = fields[:attribute]
        @expected = self.class.clean(fields[:expected])
        @actual = self.class.clean(fields[:actual])
        @message = self.class.clean(fields[:message])
        @code = fields[:code]
        freeze
      end

      # @return [Hash{String => Object}] the result without nil fields
      def to_h
        { "status" => status, "subject" => subject, "attribute" => attribute, "expected" => expected,
          "actual" => actual, "message" => message, "code" => code }.compact
      end

      # @return [String] one text report line
      def to_text
        case status
        when "pass" then "PASS #{subject}"
        when "fail" then "FAIL #{subject} #{attribute}: expected #{expected}, got #{actual}"
        else "ERROR #{subject}: #{code}"
        end
      end
    end
  end
end
