# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "backends and runner" do
  include InfraSpecHelpers

  let(:recorder) do
    Class.new do
      attr_reader :calls

      def initialize = @calls = []

      def call(argv, timeout:)
        @calls << [argv, timeout]
        ["out", "", 0]
      end
    end.new
  end

  it "Local passes the argv array through", :aggregate_failures do
    expect(IC::Backends::Local.new(runner: recorder).execute(["ls", "a b"], timeout: 3)).to eq(["out", "", 0])
    expect(recorder.calls).to eq([[["ls", "a b"], 3]])
    expect(code_of { IC::Backends::Local.new(runner: recorder).execute([]) }).to eq(:invalid_checks)
    expect(IC::Backends::Local.new).to be_a(IC::Backends::Local)
  end

  it "Docker builds docker exec with a fixed shape and escaped script", :aggregate_failures do
    backend = IC::Backends::Docker.new("web", runner: recorder)
    argv = ["dpkg-query", "-W", "-f", "${Status} ${Version}", "nginx; rm -rf /"]
    backend.execute(argv)
    sent = recorder.calls.first.first
    expect(sent.first(5)).to eq(%w[docker exec web sh -c])
    expect(sent.length).to eq(6)
    expect(Shellwords.split(sent.last)).to eq(argv)
    expect(sent.last).to include(Shellwords.escape("nginx; rm -rf /"))
    expect(backend.container).to eq("web")
  end

  it "Docker rejects bad container names" do
    expect(code_of { IC::Backends::Docker.new("web; ls") }).to eq(:invalid_name)
    expect(code_of { IC::Backends::Docker.new("-x") }).to eq(:invalid_name)
  end

  it "Fake answers, times out and defaults", :aggregate_failures do
    fake_backend = IC::Backends::Fake.new(["a"] => ["o", "e", 2], ["b"] => :timeout)
    expect(fake_backend.execute(["a"])).to eq(["o", "e", 2])
    expect(fake_backend.execute(["c"])).to eq(["", "", 127])
    expect { fake_backend.execute(["b"]) }.to raise_error(IC::CommandTimeout)
    expect(code_of { IC::Backends::Fake.new([]) }).to eq(:invalid_checks)
  end

  it "the Open3 runner runs argv arrays without a shell", :aggregate_failures, if: !Gem.win_platform? do
    runner = IC::Runner::Open3Runner.new
    expect(runner.call(["echo", "hi; ls"], timeout: 5)).to eq(["hi; ls\n", "", 0])
    expect(runner.call(["sh", "-c", "echo err >&2; exit 3"], timeout: 5)).to eq(["", "err\n", 3])
    expect(runner.call(["infra-spec-checks-no-such-program"], timeout: 5)[2]).to eq(127)
    expect(code_of { runner.call([], timeout: 1) }).to eq(:invalid_checks)
  end

  it "the Open3 runner kills a process on timeout" do
    expect { IC::Runner::Open3Runner.new.call(%w[sleep 5], timeout: 0.2) }.to raise_error(IC::CommandTimeout)
  end

  it "the Open3 runner reports signal exits as status 1", if: !Gem.win_platform? do
    expect(IC::Runner::Open3Runner.new.call(["sh", "-c", "kill -9 $$"], timeout: 5)[2]).to eq(1)
  end
end
