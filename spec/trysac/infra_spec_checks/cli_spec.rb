# frozen_string_literal: true

require "tmpdir"
require "stringio"
require_relative "helpers"

RSpec.describe "the command line" do
  include InfraSpecHelpers

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:four) do
    [{ "port" => 80 }, { "package" => "nginx", "version" => "1.30" }, { "service" => "nginx" },
     { "file" => "/etc/nginx/nginx.conf", "mode" => "0600" }]
  end

  def run_cli(args, runner: InfraSpecHelpers::ReplayRunner.new(fake))
    IC::CLI.run(args, stdout: out, stderr: err, runner: runner)
  end

  def checks_file(dir, content)
    path = File.join(dir, "checks.json")
    File.write(path, content)
    path
  end

  it "returns 1 when one of four checks fails" do
    Dir.mktmpdir do |dir|
      file = checks_file(dir, JSON.generate(four))
      expect(run_cli(["--docker", "web", file])).to eq(1)
      expect(out.string).to include("FAIL file /etc/nginx/nginx.conf mode: expected 0600, got 0644")
    end
  end

  it "returns 0 when all pass, with JSON output" do
    Dir.mktmpdir do |dir|
      four.last["mode"] = "0644"
      file = checks_file(dir, JSON.generate(four))
      expect(run_cli(["--docker", "web", "--json", file])).to eq(0)
      expect(JSON.parse(out.string)).to include("passed" => 4, "failed" => 0)
    end
  end

  it "runs locally with --local" do
    Dir.mktmpdir do |dir|
      file = checks_file(dir, '[{"port": 80}]')
      runner = InfraSpecHelpers::DirectRunner.new(fake)
      expect(run_cli(["--local", file], runner: runner)).to eq(0)
      expect(out.string).to eq("PASS port 80\n")
    end
  end

  it "returns 2 for oversize files, too many checks and bad content", :aggregate_failures do
    Dir.mktmpdir do |dir|
      expect(run_cli([checks_file(dir, "a" * 1_048_577)])).to eq(2)
      expect(run_cli([checks_file(dir, "[#{(["{\"port\": 80}"] * 1001).join(",")}]")])).to eq(2)
      expect(err.string).to include("input_too_large")
      expect(run_cli([checks_file(dir, "")])).to eq(2)
      expect(run_cli([File.join(dir, "missing.json")])).to eq(2)
      expect(run_cli([dir])).to eq(2)
      expect(err.string).to include("error: io:")
    end
  end

  it "returns 2 for usage errors" do
    [[], ["--bogus", "x"], ["--docker"], ["a.json", "b.json"]].each do |args|
      expect(run_cli(args)).to eq(2)
    end
    expect(err.string).to include("usage:")
    Dir.mktmpdir { |dir| expect(run_cli(["--docker", "bad name", checks_file(dir, "[]")])).to eq(2) }
  end
end
