# frozen_string_literal: true

require_relative "infra_spec_checks/version"
require_relative "infra_spec_checks/blank_input_error"
require_relative "infra_spec_checks/text"

# The namespace of the Trysac factory's Ruby libraries.
module Trysac
  # Declarative checks for servers and containers that verify listening ports, installed packages, running services and file modes from proc files, without a shell on the input
  module InfraSpecChecks
  end
end
