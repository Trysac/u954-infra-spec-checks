# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Process runners: objects answering call(argv, timeout:) with [stdout, stderr, status].
    module Runner
      # Runs argv arrays with Open3 and never through a shell.
      class Open3Runner
        # Most bytes read from each output stream.
        MAX_OUTPUT = 1_048_576

        # @param argv [Array<String>] program and arguments
        # @param timeout [Numeric] seconds before the process is killed
        # @return [Array(String, String, Integer)] stdout, stderr, exit status (127 when it cannot start)
        # @raise [CommandTimeout] when the process outlives the timeout
        def call(argv, timeout: Backends::DEFAULT_TIMEOUT)
          Validate.arguments(argv)
          Open3.popen3([argv.first, argv.first], *argv.drop(1)) do |stdin, out, err, thread|
            collect(stdin, [out, err], thread, timeout)
          end
        rescue SystemCallError => e
          ["", Error.clip(e.message), 127]
        end

        private

        def collect(stdin, streams, thread, timeout)
          stdin.close
          readers = streams.map { |io| Thread.new { String.new(io.read(MAX_OUTPUT).to_s, encoding: Encoding::UTF_8).scrub } }
          finish(thread, timeout)
          [readers[0].value, readers[1].value, thread.value.exitstatus || 1]
        end

        def finish(thread, timeout)
          return if thread.join(timeout)

          begin
            Process.kill("KILL", thread.pid)
          rescue Errno::ESRCH
            nil
          end
          thread.join
          raise CommandTimeout
        end
      end
    end
  end
end
