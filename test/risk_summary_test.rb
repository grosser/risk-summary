# frozen_string_literal: true
require_relative "test_helper"

SingleCov.covered!

describe RiskSummary do
  it "has a VERSION" do
    RiskSummary::VERSION.must_match /^[.\da-z]+$/
  end
end
