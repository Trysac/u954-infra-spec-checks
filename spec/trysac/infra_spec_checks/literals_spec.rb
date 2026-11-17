# frozen_string_literal: true

require_relative "helpers"

RSpec.describe "acceptance literals" do
  include InfraSpecHelpers

  def results(backend, &) = IC.define(&).run(backend).to_h["results"]

  it "treats row 0100007F:1F90 in state 0A as listening on 127.0.0.1" do
    row = "0: 0100007F:1F90 00000000:0000 0A #{InfraSpecHelpers::TAIL}\n"
    backend = fake(InfraSpecHelpers::TCP_CAT => [row, "", 0])
    expect(results(backend) { port(8080).listening(address: "127.0.0.1") }.first["status"]).to eq("pass")
  end

  it "parses the apk line 'nginx-1.30.5-r1 x86_64 {nginx} (BSD-2-Clause) [installed]'" do
    line = "nginx-1.30.5-r1 x86_64 {nginx} (BSD-2-Clause) [installed]"
    backend = fake(InfraSpecHelpers::APK => ["#{line}\n", "", 0])
    expect(results(backend) { package("nginx").installed(version: "1.30") }.first["status"]).to eq("pass")
  end

  it "parses the stat output '644 root root regular file'" do
    stat = "644 root root regular file"
    backend = fake(InfraSpecHelpers::STAT => ["#{stat}\n", "", 0])
    expect(results(backend) { file("/etc/nginx/nginx.conf").mode("0644").owner("root") }.map { it["status"] })
      .to all(eq("pass"))
  end
end
