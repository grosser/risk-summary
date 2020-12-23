# frozen_string_literal: true
require_relative "lib/risk_summary/version"

Gem::Specification.new "risk-summary", RiskSummary::VERSION do |s|
  s.summary = "Collects Risk section from all merged PRs over a given commit range"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/risk-summary"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = ">= 2.5.0"
end
