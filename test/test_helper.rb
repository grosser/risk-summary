# frozen_string_literal: true
require "bundler/setup"

require "single_cov"
SingleCov.setup :minitest

require "maxitest/global_must"
require "maxitest/autorun"
require "mocha/minitest"
require "webmock/minitest"

require "risk_summary"
