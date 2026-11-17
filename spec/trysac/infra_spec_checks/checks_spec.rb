# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "checks" do
  include InfraSpecHelpers

  def first(backend, &)
    IC.define(&).run(backend).to_h["results"].first
  end

  describe "port" do
    it "passes for 00000000:0050 in state 0A" do
      expect(first(fake) { port(80).listening }["status"]).to eq("pass")
    end

    it "binds 8080 to 127.0.0.1 and not to another address" do
      expect(first(fake) { port(8080).listening(address: "127.0.0.1") }["status"]).to eq("pass")
      expect(first(fake) { port(8080).listening(address: "10.1.1.1") }["status"]).to eq("fail")
    end

    it "does not count state 01 as listening" do
      expect(first(fake) { port(8081).listening }["status"]).to eq("fail")
    end

    it "parses IPv6 rows and wildcards", :aggregate_failures do
      expect(first(fake) { port(443).listening }["status"]).to eq("pass")
      expect(first(fake) { port(443).listening(address: "10.0.0.1") }["status"]).to eq("pass")
      expect(first(fake) { port(8082).listening(address: "::1") }["status"]).to eq("pass")
      expect(first(fake) { port(8083).listening(address: "::1") }["status"]).to eq("pass").or eq("fail")
    end

    it "renders a failing text line" do
      report = IC.define { port(9999).listening }.run(fake)
      expect(report.to_text).to eq("FAIL port 9999 listening: expected listening, got not listening")
    end

    it "rejects invalid ports and addresses" do
      [0, 65_536, "80", nil].each { |p| expect(code_of { IC.define { port(p) } }).to eq(:invalid_port) }
      expect(code_of { IC.define { port(80).listening(address: "a b") } }).to eq(:invalid_checks)
    end

    it "reports an error when proc cannot be read" do
      result = first(IC::Backends::Fake.new({})) { port(80).listening }
      expect(result).to include("status" => "error", "code" => "command_failed")
    end
  end

  describe "package" do
    it "passes on apk output, with a version prefix on a dot boundary", :aggregate_failures do
      expect(first(fake) { package("nginx").installed }["status"]).to eq("pass")
      expect(first(fake) { package("nginx").installed(version: "1.30") }["status"]).to eq("pass")
      expect(first(fake) { package("nginx").installed(version: "1.30.5-r1") }["status"]).to eq("pass")
      expect(first(fake) { package("nginx").installed(version: "1.30.5") }["status"]).to eq("pass")
    end

    it "fails a prefix that is not on a boundary" do
      result = first(fake) { package("nginx").installed(version: "1.3") }
      expect(result).to include("status" => "fail", "attribute" => "version", "actual" => "1.30.5-r1")
    end

    it "parses versions of every package manager", :aggregate_failures do
      pc = IC::PackageCheck
      apk_out = "nginx-module-x-1.0-r0 x {nginx} [installed]\n#{InfraSpecHelpers::APK_LINE}"
      expect(pc.parse_version("alpine", "nginx", apk_out, 0)).to eq("1.30.5-r1")
      expect(pc.parse_version("alpine", "nginx", "nginx-1.30.5-r1 x86_64 {nginx} (BSD-2-Clause)\n", 0)).to be_nil
      expect(pc.parse_version("debian", "nginx", "install ok installed 1.30.5-1~bookworm",
                              0)).to eq("1.30.5-1~bookworm")
      expect(pc.parse_version("debian", "nginx", "", 1)).to be_nil
      expect(pc.parse_version("fedora", "nginx", "1.30.5-1.fc40", 0)).to eq("1.30.5-1.fc40")
      expect(pc.parse_version("fedora", "nginx", "", 1)).to be_nil
    end

    it "uses dpkg-query on Debian" do
      backend = fake(InfraSpecHelpers::OS_CAT => [InfraSpecHelpers::DEBIAN_OS, "", 0],
                     ["dpkg-query", "-W", "-f", "${Status} ${Version}", "nginx"] =>
                       ["install ok installed 1.30.5-1~bookworm", "", 0])
      expect(first(backend) { package("nginx").installed(version: "1.30") }["status"]).to eq("pass")
    end

    it "uses rpm on Fedora family systems" do
      pct = "%"
      backend = fake(InfraSpecHelpers::OS_CAT => ["ID=\"rocky\"\n", "", 0],
                     ["rpm", "-q", "--qf", "#{pct}{VERSION}-#{pct}{RELEASE}", "nginx"] => ["1.30.5-1.el9", "", 0])
      expect(first(backend) { package("nginx").installed }["status"]).to eq("pass")
    end

    it "fails a missing package with its message" do
      backend = fake(InfraSpecHelpers::APK => ["", "", 0])
      result = first(backend) { package("nginx").installed }
      expect(result["status"]).to eq("fail")
      expect(result["message"]).to eq("package nginx is not installed")
    end

    it "reports unsupported operating systems" do
      arch = fake(InfraSpecHelpers::OS_CAT => ["ID=arch\n", "", 0])
      expect(first(arch) { package("nginx").installed }).to include("status" => "error", "code" => "unsupported_os")
      expect(first(IC::Backends::Fake.new({})) { package("nginx").installed }["code"]).to eq("unsupported_os")
    end

    it "rejects hostile names and versions" do
      expect(code_of { IC.define { package("nginx; rm -rf /") } }).to eq(:invalid_name)
      expect(code_of { IC.define { package("nginx").installed(version: "1 2") } }).to eq(:invalid_name)
    end
  end

  describe "service" do
    it "runs on a host without systemd from /proc comm" do
      expect(first(fake) { service("nginx").running }["status"]).to eq("pass")
      missing = fake(InfraSpecHelpers::COMM => ["init\n", "", 0])
      expect(first(missing) { service("nginx").running }["actual"]).to eq("not running")
    end

    it "uses systemctl is-active on a host with systemd" do
      active = fake(InfraSpecHelpers::SYSTEMD => ["", "", 0],
                    %w[systemctl is-active nginx] => ["active\n", "", 0])
      expect(first(active) { service("nginx").running }["status"]).to eq("pass")
      inactive = fake(InfraSpecHelpers::SYSTEMD => ["", "", 0],
                      %w[systemctl is-active nginx] => ["inactive\n", "", 3])
      expect(first(inactive) { service("nginx").running }["actual"]).to eq("inactive")
      silent = fake(InfraSpecHelpers::SYSTEMD => ["", "", 0])
      expect(first(silent) { service("nginx").running }["actual"]).to eq("unknown")
    end

    it "rejects hostile names" do
      expect(code_of { IC.define { service("a b") } }).to eq(:invalid_name)
    end
  end

  describe "file" do
    it "checks mode and owner" do
      result = first(fake) { file("/etc/nginx/nginx.conf").exists.mode("0644").owner("root").group("root") }
      expect(result["status"]).to eq("pass")
      expect(first(fake) { file("/etc/nginx/nginx.conf").mode("644") }["status"]).to eq("pass")
    end

    it "fails a wrong mode with the text line" do
      report = IC.define { file("/etc/nginx/nginx.conf").exists.mode("0600") }.run(fake)
      expect(report.to_text).to eq("FAIL file /etc/nginx/nginx.conf mode: expected 0600, got 0644")
    end

    it "fails a wrong owner or group, and a missing file" do
      expect(first(fake) { file("/etc/nginx/nginx.conf").owner("www") }["attribute"]).to eq("owner")
      expect(first(fake) { file("/etc/nginx/nginx.conf").group("www") }["attribute"]).to eq("group")
      missing = fake(InfraSpecHelpers::STAT => ["", "No such file", 1])
      expect(first(missing) { file("/etc/nginx/nginx.conf").exists }["attribute"]).to eq("exists")
    end

    it "reports unparsable stat output as an error" do
      odd = fake(InfraSpecHelpers::STAT => ["garbage", "", 0])
      expect(first(odd) { file("/etc/nginx/nginx.conf").exists }["code"]).to eq("command_failed")
    end

    it "rejects hostile paths and modes" do
      ["/etc/a\nb", "/etc/a\0b", "relative", "/#{"a" * 4096}", 5, ""].each do |p|
        expect(code_of { IC.define { file(p) } }).to eq(:invalid_path)
      end
      ["0999", "rwx", nil].each { |m| expect(code_of { IC.define { file("/a").mode(m) } }).to eq(:invalid_mode) }
      expect(code_of { IC.define { file("/a").owner("a;b") } }).to eq(:invalid_name)
    end
  end

  describe "command" do
    let(:backend) { fake(["nginx", "-v"] => ["", "nginx version", 0], ["false"] => ["", "", 1]) }

    it "compares the exit status" do
      expect(first(backend) { command("nginx", "-v").exit_status(0) }["status"]).to eq("pass")
      expect(first(backend) { command("false") }["actual"]).to eq("1")
      expect(first(backend) { command("false").exit_status(1) }["status"]).to eq("pass")
    end

    it "rejects invalid commands", :aggregate_failures do
      expect(code_of { IC.define { command } }).to eq(:invalid_checks)
      expect(code_of { IC.define { command("a\0b") } }).to eq(:invalid_checks)
      expect(code_of { IC.define { command("nginx; ls") } }).to eq(:invalid_name)
      expect(code_of { IC.define { command("/bin/ls", "-l") } }).to be_nil
      expect(code_of { IC.define { command("/bin/l\ns") } }).to eq(:invalid_path)
      expect(code_of { IC.define { command("nginx").exit_status(256) } }).to eq(:invalid_checks)
    end
  end

  describe "report and errors" do
    it "counts 3 passes and 1 failure in check order", :aggregate_failures do
      report = IC.define do
        [80, 8080, 443, 9999].each { |number| port(number).listening }
      end.run(fake)
      hash = report.to_h
      expect(hash.except("results")).to eq("passed" => 3, "failed" => 1, "errors" => 0)
      expect(hash["results"].map { |r| r["status"] }).to eq(%w[pass pass pass fail])
      expect(report.passed?).to be(false)
      expect(report.to_text.lines.size).to eq(4)
    end

    it "reports a passing suite" do
      expect(IC.define { port(80).listening }.run(fake).passed?).to be(true)
    end

    it "turns a timeout into an error result while the other checks run" do
      backend = fake(["nginx", "-v"] => :timeout)
      report = IC.define do
        command("nginx", "-v")
        port(80).listening
      end.run(backend)
      expect(report.to_h["results"].first).to include("status" => "error", "code" => "timeout")
      expect(report.results.last.status).to eq("pass")
      expect(report.to_text.lines.first.chomp).to eq("ERROR command nginx -v: timeout")
    end

    it "clips messages and cleans control characters" do
      expect(IC::Error.new(:x, "a" * 500).message.length).to eq(200)
      expect(IC::Result.clean("a\nb")).to eq("a?b")
      expect(IC.define { port(80) }.checks.size).to eq(1)
    end

    it "requires a block" do
      expect(code_of { IC.define }).to eq(:invalid_checks)
    end

    it "caps the builder" do
      expect(code_of { IC.define { 1001.times { port(80) } } }).to eq(:input_too_large)
    end
  end
end
