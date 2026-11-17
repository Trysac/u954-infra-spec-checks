# frozen_string_literal: true

require "shellwords"
require "trysac/infra_spec_checks"

IC = Trysac::InfraSpecChecks unless defined?(IC)

# Fixtures and fakes shared by the specs (hand-written in the documented formats of each tool).
module InfraSpecHelpers
  OS_CAT = %w[cat /etc/os-release].freeze
  TCP_CAT = %w[cat /proc/net/tcp /proc/net/tcp6].freeze
  COMM = ["sh", "-c", "cat /proc/[0-9]*/comm 2>/dev/null"].freeze
  SYSTEMD = %w[test -d /run/systemd/system].freeze
  STAT = ["stat", "-c", "%a %U %G %F", "/etc/nginx/nginx.conf"].freeze
  APK = %w[apk list --installed nginx].freeze
  DEBIAN_OS = "PRETTY_NAME=\"Debian GNU/Linux 12\"\nID=debian\nID_LIKE=other\n"
  ALPINE_OS = "NAME=\"Alpine Linux\"\nID=alpine\nVERSION_ID=3.20.1\n"
  APK_LINE = "nginx-1.30.5-r1 x86_64 {nginx} (BSD-2-Clause) [installed]\n"
  TAIL = "00000000:00000000 00:00000000 00000000     0        0 1 1 0 100 0 0 10 0"
  TCP = <<~TCP.freeze
    sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
     0: 00000000:0050 00000000:0000 0A #{TAIL}
     1: 0100007F:1F90 00000000:0000 0A #{TAIL}
     2: 0100007F:1F91 0100007F:C350 01 #{TAIL}
       0: 00000000000000000000000000000000:01BB 00000000000000000000000000000000:0000 0A #{TAIL}
       1: 00000000000000000000000001000000:1F92 00000000000000000000000000000000:0000 0A #{TAIL}
       2: 0000000000000000FFFF00000100007F:1F93 00000000000000000000000000000000:0000 0A #{TAIL}
  TCP

  # Replays a Fake backend behind a docker exec argv by splitting the script back into words.
  class ReplayRunner
    attr_reader :calls

    def initialize(fake)
      @fake = fake
      @calls = []
    end

    def call(argv, timeout:)
      @calls << argv
      @fake.execute(Shellwords.split(argv.last), timeout: timeout)
    end
  end

  # Passes argv straight to a Fake backend.
  class DirectRunner
    def initialize(fake)
      @fake = fake
    end

    def call(argv, timeout:) = @fake.execute(argv, timeout: timeout)
  end

  def fake(extra = {})
    base = {
      TCP_CAT => [TCP, "", 0], OS_CAT => [ALPINE_OS, "", 0], APK => [APK_LINE, "", 0],
      SYSTEMD => ["", "", 1], COMM => ["init\nnginx\n", "", 0], STAT => ["644 root root regular file\n", "", 0]
    }
    IC::Backends::Fake.new(base.merge(extra))
  end

  def code_of
    yield
    nil
  rescue IC::Error => e
    e.code
  end
end
