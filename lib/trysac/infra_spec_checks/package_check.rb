# frozen_string_literal: true

module Trysac
  module InfraSpecChecks
    # Checks that a package is installed, using the package manager of the detected OS.
    class PackageCheck < Check
      # Probe that reads the OS identity.
      OS_RELEASE = %w[cat /etc/os-release].freeze
      # Characters that may follow a version prefix.
      BOUNDARIES = [".", "-", "~", "+"].freeze

      # Extracts the installed version from package-manager output.
      #
      # @param os [String] the os-release ID
      # @param name [String] the package name
      # @param out [String] the stdout of the probe
      # @param status [Integer] the exit status of the probe
      # @return [String, nil] the version, or nil when not installed
      def self.parse_version(os, name, out, status)
        case os
        when "alpine" then alpine_version(name, out)
        when "debian", "ubuntu"
          match = status.zero? ? /\Ainstall ok installed (\S+)\z/.match(out.strip) : nil
          match && match[1]
        else
          version = out.strip
          status.zero? && !version.empty? ? version : nil
        end
      end

      # Finds the installed version of a package in `apk list --installed` output.
      #
      # @param name [String] the package name
      # @param out [String] the output of `apk list --installed`
      # @return [String, nil] the installed version, or nil when the package is not installed
      def self.alpine_version(name, out)
        pattern = /\A#{Regexp.escape(name)}-(\d\S*) /
        out.each_line do |line|
          match = pattern.match(line)
          return match[1] if match && line.include?("[installed]")
        end
        nil
      end

      # @param name [String] the package name
      # @raise [Error] :invalid_name
      def initialize(name)
        super()
        @name = Validate.name(name)
        @version = nil
      end

      # Requires the package, optionally with a version prefix on a boundary.
      #
      # @param version [String, nil] the expected version prefix
      # @return [PackageCheck] self
      def installed(version: nil)
        @version = Validate.version(version) unless version.nil?
        self
      end

      # @return [String] the subject
      def subject = "package #{@name}"

      # @param backend [#execute] the backend
      # @return [Result] the outcome
      def evaluate(backend)
        os = os_id(backend)
        out, _err, status = backend.execute(query(os))
        version = self.class.parse_version(os, @name, out, status)
        if version.nil?
          return Result.failure(subject, "installed", "installed", "not installed",
                                "package #{@name} is not installed")
        end
        return Result.failure(subject, "version", @version, version) unless version_ok?(version)

        Result.success(subject)
      end

      private

      def version_ok?(version)
        return true if @version.nil? || version == @version

        version.start_with?(@version) && BOUNDARIES.include?(version[@version.length])
      end

      def os_id(backend)
        out, _err, status = backend.execute(OS_RELEASE)
        line = status.zero? ? out.each_line.find { |l| l.start_with?("ID=") } : nil
        return nil unless line

        line.strip.delete_prefix("ID=").delete("\"'").downcase
      end

      def query(os)
        pct = "%"
        case os
        when "alpine" then ["apk", "list", "--installed", @name]
        when "debian", "ubuntu" then ["dpkg-query", "-W", "-f", "${Status} ${Version}", @name]
        when "fedora", "rhel", "rocky", "almalinux" then ["rpm", "-q", "--qf", "#{pct}{VERSION}-#{pct}{RELEASE}", @name]
        else raise Error.new(:unsupported_os, "unsupported or unknown operating system")
        end
      end
    end
  end
end
