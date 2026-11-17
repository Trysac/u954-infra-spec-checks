# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Checks the exit status of a command run as an argv array.
    class CommandCheck < Check
      # @param argv [Array<String>] program and arguments
      # @raise [Error] :invalid_name, :invalid_path or :invalid_checks
      def initialize(*argv)
        super()
        @argv = Validate.arguments(argv).dup.freeze
        Validate.program(@argv.first)
        @status = 0
      end

      # @param status [Integer] the expected exit status, 0..255
      # @return [CommandCheck] self
      # @raise [Error] :invalid_checks
      def exit_status(status)
        raise Error.new(:invalid_checks, "exit status must be 0..255") unless status.is_a?(Integer) && status.between?(
          0, 255
        )

        @status = status
        self
      end

      # @return [String] the subject
      def subject = "command #{@argv.join(" ")}"

      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def evaluate(backend)
        _out, _err, status = backend.execute(@argv)
        return Result.success(subject) if status == @status

        Result.failure(subject, "exit_status", @status, status)
      end
    end
  end
end
