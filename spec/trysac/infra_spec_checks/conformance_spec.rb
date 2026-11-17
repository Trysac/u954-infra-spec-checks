# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "conformance: nginx container", :conformance do
  let(:image) { "nginx:1.30.5-alpine@sha256:0985e772fb9f729e6fa0980da05fca5d9c468e870eed43071545afa9d2e27d94" }

  def port_ready?(backend)
    50.times do
      listing, = backend.execute(%w[cat /proc/net/tcp])
      return true if IC::PortCheck.listeners(listing).any? { |_address, port| port == 80 }

      sleep 0.1
    end
    false
  end

  def start_container(runner)
    out, _err, status = runner.call(["docker", "run", "-d", "--rm", image], timeout: 300)
    expect(status).to eq(0)
    out.strip
  end

  def run_suite(backend)
    IC.define do
      port(80).listening
      package("nginx").installed(version: "1.30.5")
      service("nginx").running
      file("/etc/nginx/nginx.conf").exists
      package("httpd").installed
    end.run(backend)
  end

  before do
    skip "FABRICA_CI is not set" unless ENV["FABRICA_CI"] == "1"
    skip "docker is missing" unless system("docker", "--version", out: File::NULL, err: File::NULL)
  end

  it "verifies a real container" do
    runner = IC::Runner::Open3Runner.new
    id = start_container(runner)
    begin
      backend = IC::Backends::Docker.new(id, runner: runner)
      expect(port_ready?(backend)).to be(true)
      expect(run_suite(backend).results.map(&:status)).to eq(%w[pass pass pass pass fail])
    ensure
      runner.call(["docker", "rm", "-f", id], timeout: 60)
    end
  end
end
