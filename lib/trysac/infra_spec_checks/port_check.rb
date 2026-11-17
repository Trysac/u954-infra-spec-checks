# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Checks that a TCP port is listening, from /proc/net/tcp and /proc/net/tcp6.
    class PortCheck < Check
      # The probe command.
      PROBE = %w[cat /proc/net/tcp /proc/net/tcp6].freeze
      # One socket row of proc(5).
      ROW = /\A\s*\d+:\s+([0-9A-Fa-f]{32}|[0-9A-Fa-f]{8}):([0-9A-Fa-f]{4})\s+\S+\s+([0-9A-Fa-f]{2})\b/
      # Addresses that listen on every interface.
      WILDCARDS = %w[0.0.0.0 ::].freeze

      # Parses the listening sockets of a proc file.
      #
      # @param text [String] the proc file text
      # @return [Array<Array(String, Integer)>] address and port of every state 0A row
      def self.listeners(text)
        text.scrub.each_line.filter_map do |line|
          match = ROW.match(line)
          next unless match && match[3].upcase == "0A"

          [decode(match[1]), match[2].hex]
        end
      end

      # Decodes a little-endian hex address from /proc/net/tcp or tcp6.
      #
      # @param hex [String] 8 hex digits for IPv4 or 32 for IPv6
      # @return [String] the dotted IPv4 address or the colon-separated IPv6 address
      def self.decode(hex)
        return hex.scan(/../).reverse.map(&:hex).join(".") if hex.length == 8

        decode6(hex)
      end

      # Splits a /proc/net/tcp6 hex address into its eight IPv6 groups, in network order.
      #
      # @param hex [String] the 32 hex digits, stored as four little-endian 32-bit words
      # @return [Array<String>] the eight hex groups without leading zeros
      def self.groups6(hex)
        words = hex.scan(/.{8}/).map { |word| word.scan(/../).reverse.join }
        words.join.scan(/.{4}/).map { |group| group.sub(/\A0+(?=.)/, "") }
      end

      # Decodes a /proc/net/tcp6 hex address into IPv6 text.
      #
      # @param hex [String] the 32 hex digits, stored as four little-endian 32-bit words
      # @return [String] "::" for any, "::1" for loopback, otherwise the eight groups joined by colons
      def self.decode6(hex)
        groups = groups6(hex)
        return "::" if groups.all?("0")
        return "::1" if groups == %w[0 0 0 0 0 0 0 1]

        groups.join(":")
      end

      # @param port [Integer] the port, 1..65535
      # @raise [Error] :invalid_port
      def initialize(port)
        super()
        @port = Validate.port(port)
        @address = nil
      end

      # Requires the port to listen, optionally on one address.
      #
      # @param address [String, nil] a literal address such as "127.0.0.1"
      # @return [PortCheck] self
      def listening(address: nil)
        @address = Validate.address(address) unless address.nil?
        self
      end

      # @return [String] the subject
      def subject = "port #{@port}"

      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def evaluate(backend)
        out, _err, status = backend.execute(PROBE)
        raise Error.new(:command_failed, "cannot read /proc/net/tcp") if out.strip.empty? && !status.zero?

        return Result.success(subject) if listening_in?(out)

        Result.failure(subject, "listening", "listening", "not listening")
      end

      private

      def listening_in?(out)
        self.class.listeners(out).any? { |address, port| port == @port && address_ok?(address) }
      end

      def address_ok?(address) = @address.nil? || address == @address || WILDCARDS.include?(address)
    end
  end
end
