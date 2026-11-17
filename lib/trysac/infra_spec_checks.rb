# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "infra_spec_checks/version"
require_relative "infra_spec_checks/blank_input_error"
require_relative "infra_spec_checks/text"
require_relative "infra_spec_checks/error"
require_relative "infra_spec_checks/validate"
require_relative "infra_spec_checks/result"
require_relative "infra_spec_checks/report"
require_relative "infra_spec_checks/runner"
require_relative "infra_spec_checks/backends"
require_relative "infra_spec_checks/backends/local"
require_relative "infra_spec_checks/backends/docker"
require_relative "infra_spec_checks/backends/fake"
require_relative "infra_spec_checks/check"
require_relative "infra_spec_checks/port_check"
require_relative "infra_spec_checks/package_check"
require_relative "infra_spec_checks/service_check"
require_relative "infra_spec_checks/file_check"
require_relative "infra_spec_checks/command_check"
require_relative "infra_spec_checks/suite"
require_relative "infra_spec_checks/builder"
require_relative "infra_spec_checks/cli"

# The namespace of the Trysac factory's Ruby libraries.
module Trysac
  # Declarative checks for servers and containers.
  module InfraSpecChecks
    # Builds a suite from a block evaluated by a {Builder}.
    #
    # @yield the block calling port, package, service, file and command
    # @return [Suite] the suite of check objects
    # @raise [Error] when no block is given
    def self.define(&block)
      raise Error.new(:invalid_checks, "a block is required") unless block

      builder = Builder.new
      builder.instance_exec(&block)
      Suite.new(builder.checks)
    end
  end
end
