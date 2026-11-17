# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Checks that a service is running: systemctl with systemd, else the process names in /proc.
    class ServiceCheck < Check
      # Probe for a systemd host.
      SYSTEMD = %w[test -d /run/systemd/system].freeze
      # Probe listing process names.
      COMM = ["sh", "-c", "cat /proc/[0-9]*/comm 2>/dev/null"].freeze
      # Longest process name the kernel keeps.
      COMM_LENGTH = 15

      # @param name [String] the service name
      # @raise [Error] :invalid_name
      def initialize(name)
        super()
        @name = Validate.name(name)
      end

      # @return [ServiceCheck] self
      def running = self

      # @return [String] the subject
      def subject = "service #{@name}"

      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def evaluate(backend)
        _out, _err, systemd = backend.execute(SYSTEMD)
        state = systemd.zero? ? systemd_state(backend) : process_state(backend)
        state == "running" ? Result.success(subject) : Result.failure(subject, "running", "running", state)
      end

      private

      def systemd_state(backend)
        out, = backend.execute(["systemctl", "is-active", @name])
        if out.strip == "active"
          "running"
        else
          (out.strip.empty? ? "unknown" : out.strip)
        end
      end

      def process_state(backend)
        out, = backend.execute(COMM)
        out.scrub.each_line.any? { |l| l.strip == @name[0, COMM_LENGTH] } ? "running" : "not running"
      end
    end
  end
end
