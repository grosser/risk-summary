# frozen_string_literal: true
require_relative "test_helper"

SingleCov.covered!

describe RiskSummary do
  describe RiskSummary::RiskParser do
    describe ".parse" do
      def call(text)
        RiskSummary::RiskParser.parse(text)
      end

      it "finds nothing in empty" do
        call("").must_equal :missing
      end

      it "finds nothing in regular text" do
        call("Wut ?").must_equal :missing
      end

      it "finds risks" do
        call("Wut ?\n## Risks\n- stuff").must_equal "- stuff"
      end

      it "ignores empty risks" do
        call("Wut ?\n## Risks\n").must_equal :missing
      end

      it "ignores non-risks" do
        call("Wut ?\n## Risks\n- None").must_equal :none
      end
    end
  end

  describe ".cli" do
    def capture_stdout
      old = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old
    end

    def with_env(hash)
      old = ENV.to_h
      hash.each { |k, v| ENV[k.to_s] = v }
      yield
    ensure
      ENV.replace old
    end

    let(:exited) { Class.new(RuntimeError) }
    before { RiskSummary.stubs(:exit).with { |code| raise exited, code } } # make tests not crash
    before do
      RiskSummary.stubs(:`).returns("TOKEN") # never use real token
      `true` # see $? with an success
    end
    around { |t| with_env(GITHUB_TOKEN: nil, &t) } # never use real token

    it "shows version" do
      capture_stdout do
        assert_raises(exited) { RiskSummary.cli(["-v"]) }.message.must_equal "0"
      end.must_equal "#{RiskSummary::VERSION}\n"
    end

    it "shows help" do
      capture_stdout do
        assert_raises(exited) { RiskSummary.cli(["-h"]) }.message.must_equal "0"
      end.must_include "Usage:"
    end

    it "shows help for bad arguments" do
      capture_stdout do
        assert_raises(exited) { RiskSummary.cli([]) }.message.must_equal "1"
      end.must_include "Usage:"
    end

    it "prints diff" do
      stub_request(:get, "https://api.github.com/repos/foo/bar/compare/baz")
        .with(headers: { 'Authorization' => 'token TOKEN' })
        .to_return(body: { commits: [{ sha: "a" }] }.to_json)
      stub_request(:get, "https://api.github.com/repos/foo/bar/commits/a/pulls")
        .with(headers: { 'Authorization' => 'token TOKEN' })
        .to_return(body: [
          { body: "## Risks\n- one", number: "1", html_url: "http" },
          { body: "nope", number: "2", html_url: "http" },
          { body: "## Risks\n", number: "3", html_url: "http" },
          { body: "## Risks\n None", number: "4", html_url: "http" }
        ].to_json)

      capture_stdout do
        RiskSummary.cli(["foo/bar", "baz"])
      end.must_equal <<~MARKDOWN
        - one
        - missing risks from [#2](http)
        - missing risks from [#3](http)
      MARKDOWN
    end

    it "does not use auth when no token was given" do
      `false` # see $? with failure
      stub_request(:get, "https://api.github.com/repos/foo/bar/compare/baz")
        .with { |r| r.headers["Authorization"].must_be_nil }
        .to_return(body: { commits: [] }.to_json)

      capture_stdout do
        RiskSummary.cli(["foo/bar", "baz"])
      end.must_equal ""
    end

    it "shows http trouble" do
      stub_request(:get, "https://api.github.com/repos/foo/bar/compare/baz")
        .to_return(status: 400, body: "WUT")

      assert_raises(RuntimeError) do
        RiskSummary.cli(["foo/bar", "baz"])
      end.message.must_equal <<~ERR.rstrip
        Bad response 400 from https://api.github.com/repos/foo/bar/compare/baz:
        WUT
      ERR
    end
  end
end
