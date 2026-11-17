# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Base error of the library; every failure carries a stable machine-readable code.
    class Error < ArgumentError
      # Longest message, in characters.
      MAX_MESSAGE = 200

      # @return [Symbol] the stable machine-readable code
      attr_reader :code

      # Cuts text to the maximum message length.
      #
      # @param text [#to_s] the text
      # @return [String] at most 200 characters
      def self.clip(text)
        text.to_s[0, MAX_MESSAGE]
      end

      # @param code [Symbol] the machine-readable code
      # @param message [String, nil] a human message that never embeds raw input
      def initialize(code, message = nil)
        @code = code
        super(self.class.clip(message || code.to_s))
      end
    end

    # Raised when a command exceeds its timeout.
    class CommandTimeout < Error
      # @param message [String] the message
      def initialize(message = "command timed out")
        super(:timeout, message)
      end
    end
  end
end
