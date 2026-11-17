# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Checks that a file exists and optionally its mode, owner and group, from stat.
    class FileCheck < Check
      # Output of stat -c '%a %U %G %F'.
      STAT = /\A(\d{1,4}) (\S+) (\S+) (.+)\z/

      # @param path [String] an absolute path
      # @raise [Error] :invalid_path
      def initialize(path)
        super()
        @path = Validate.path(path)
        @expected = {}
      end

      # @return [FileCheck] self
      def exists = self

      # @param value [String] an octal mode such as "0644"
      # @return [FileCheck] self
      # @raise [Error] :invalid_mode
      def mode(value)
        @expected["mode"] = Validate.mode(value)
        self
      end

      # @param value [String] the owner name
      # @return [FileCheck] self
      # @raise [Error] :invalid_name
      def owner(value)
        @expected["owner"] = Validate.name(value)
        self
      end

      # @param value [String] the group name
      # @return [FileCheck] self
      # @raise [Error] :invalid_name
      def group(value)
        @expected["group"] = Validate.name(value)
        self
      end

      # @return [String] the subject
      def subject = "file #{@path}"

      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def evaluate(backend)
        out, _err, status = backend.execute(["stat", "-c", "%a %U %G %F", @path])
        return Result.failure(subject, "exists", "exists", "missing") unless status.zero?

        compare(parse_stat(out))
      end

      private

      def parse_stat(out)
        match = STAT.match(out.strip)
        raise Error.new(:command_failed, "unexpected stat output") unless match

        { "mode" => match[1].rjust(4, "0"), "owner" => match[2], "group" => match[3] }
      end

      def compare(actual)
        differs = %w[mode owner group].find { |attr| @expected.key?(attr) && @expected[attr] != actual[attr] }
        return Result.success(subject) unless differs

        Result.failure(subject, differs, @expected[differs], actual[differs])
      end
    end
  end
end
