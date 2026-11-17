# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "properties" do
  include InfraSpecHelpers

  let(:rng) { Random.new(954) }
  let(:chars) { [*"a".."z", *"0".."9", " ", ";", "$", "`", "|", "&", "\n", "'", "\"", "-", ".", "/", "\\"] }

  def random_text
    Array.new(rng.rand(1..12)) { chars[rng.rand(chars.size)] }.join
  end

  it "accepts exactly the names that match the grammar" do
    300.times do
      text = random_text
      if text.match?(/\A[A-Za-z0-9][A-Za-z0-9._+:@-]{0,127}\z/)
        expect(IC::Validate.name(text)).to eq(text)
      else
        expect(code_of { IC::Validate.name(text) }).to eq(:invalid_name)
      end
    end
  end

  it "round-trips every argument through the Docker script" do
    runner = InfraSpecHelpers::ReplayRunner.new(IC::Backends::Fake.new({}))
    backend = IC::Backends::Docker.new("web", runner: runner)
    200.times do
      argv = ["echo", random_text, random_text]
      backend.execute(argv)
      expect(Shellwords.split(runner.calls.last.last)).to eq(argv)
    end
  end

  it "accepts every port in range and rejects the neighbours" do
    100.times { |i| expect(IC::Validate.port(rng.rand(1..65_535) + (i * 0))).to be_between(1, 65_535) }
    [0, -1, 65_536, 70_000].each { |p| expect(code_of { IC::Validate.port(p) }).to eq(:invalid_port) }
  end

  it "normalises modes to four octal digits" do
    100.times do
      mode = format("%03o", rng.rand(0..0o777))
      expect(IC::Validate.mode(mode)).to match(/\A0[0-7]{3}\z/)
    end
  end

  it "never reports a listener for a non-LISTEN state" do
    100.times do
      state = format("%02X", rng.rand(0..255))
      next if state == "0A"

      row = "0: 00000000:0050 00000000:0000 #{state} #{InfraSpecHelpers::TAIL}"
      expect(IC::PortCheck.listeners(row)).to eq([])
    end
  end
end
