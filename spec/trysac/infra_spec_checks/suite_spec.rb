# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "suite" do
  include InfraSpecHelpers

  def described_class = IC::Suite

  let(:sample) do
    '[{"port": 80}, {"package": "nginx", "version": "1.30"}, {"service": "nginx"}, ' \
      '{"file": "/etc/nginx/nginx.conf", "mode": "0644", "owner": "root"}, ' \
      '{"command": ["nginx", "-v"], "exit_status": 0}]'
  end

  it "builds the same checks as the DSL" do
    suite = described_class.from_json(sample)
    expect(suite.checks.map(&:subject)).to eq(["port 80", "package nginx", "service nginx",
                                               "file /etc/nginx/nginx.conf", "command nginx -v"])
    backend = fake(["nginx", "-v"] => ["", "", 0])
    expect(suite.run(backend).passed?).to be(true)
  end

  it "supports address, group and optional keys" do
    json = '[{"port": 8080, "address": "127.0.0.1"}, {"file": "/a", "group": "root"}, {"command": ["ls"]}]'
    expect(described_class.from_json(json).checks.size).to eq(3)
  end

  it "rejects invalid documents" do
    {
      "not json" => :invalid_checks, "{}" => :invalid_checks, "[1]" => :invalid_checks,
      '[{"nothing": 1}]' => :invalid_checks, '[{"port": 80, "service": "a"}]' => :invalid_checks,
      '[{"port": 80, "extra": 1}]' => :invalid_checks, '[{"command": "ls"}]' => :invalid_checks,
      '[{"port": 0}]' => :invalid_port, '[{"package": "a;b"}]' => :invalid_name,
      '[{"file": "/a", "mode": null}]' => :invalid_mode, "[[[[[[[[[[1]]]]]]]]]]" => :invalid_checks
    }.each { |text, code| expect(code_of { described_class.from_json(text) }).to eq(code), text }
    expect(code_of { described_class.from_json(nil) }).to eq(:invalid_checks)
  end

  it "enforces size limits" do
    too_many = "[#{(["{\"port\": 80}"] * 1001).join(",")}]"
    expect(code_of { described_class.from_json(too_many) }).to eq(:input_too_large)
    expect(code_of { described_class.from_json(" " * 1_048_577) }).to eq(:input_too_large)
    exact = "[#{(["{\"port\": 80}"] * 1000).join(",")}]"
    expect(described_class.from_json(exact).checks.size).to eq(1000)
  end
end
