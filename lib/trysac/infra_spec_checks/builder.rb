# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # The object a define block is evaluated against; it only builds check objects.
    class Builder
      # @return [Array<Check>] the checks added so far
      attr_reader :checks

      def initialize
        @checks = []
      end

      # @param number [Integer] the port
      # @return [PortCheck] the new check
      def port(number) = add(PortCheck.new(number))

      # @param name [String] the package name
      # @return [PackageCheck] the new check
      def package(name) = add(PackageCheck.new(name))

      # @param name [String] the service name
      # @return [ServiceCheck] the new check
      def service(name) = add(ServiceCheck.new(name))

      # @param path [String] the absolute path
      # @return [FileCheck] the new check
      def file(path) = add(FileCheck.new(path))

      # @param argv [Array<String>] program and arguments
      # @return [CommandCheck] the new check
      def command(*argv) = add(CommandCheck.new(*argv))

      private

      def add(check)
        raise Error.new(:input_too_large, "more than #{Suite::MAX_CHECKS} checks") if checks.size >= Suite::MAX_CHECKS

        checks << check
        check
      end
    end
  end
end
