# frozen_string_literal: true
require "optparse"

module RiskSummary
  VERSION = "0.0.0"

  class << self
    def cli(argv)
      OptionParser.new do |opts|
        opts.banner = <<~BANNER
          Collects Risk section from all merged PRs over a given commit range

          Usage:
              risk-summary v4..v12

          Options:
        BANNER
        opts.on("-h", "--help", "Show this.") do
          puts opts
          exit 0
        end
        opts.on("-v", "--version", "Show Version") do
          puts VERSION
          exit 0
        end
      end.parse!(argv)
    end
  end
end
