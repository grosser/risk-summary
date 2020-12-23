# frozen_string_literal: true
require "optparse"
require "net/http"
require "json"

module RiskSummary
  VERSION = "0.0.0"

  # copied from https://github.com/zendesk/samson/blob/master/app/models/changeset/pull_request.rb
  # modified to use unsafe regex stripping
  module RiskParser
    class << self
      def parse(text)
        risks = parse_risks(text)
        if risks.match?(/\A\s*-?\s*None\Z/i)
          []
        elsif risks.empty?
          nil
        else
          risks
        end
      end

      private

      def parse_risks(body)
        body_stripped = body.gsub(%r{</?[^>]+?>}, "") # not safe, but much simpler than pulling in nokogiri
        section_content('Risks', body_stripped).to_s.rstrip.sub(/\A\s*\n/, "")
      end

      def section_content(section_title, text)
        # ### Risks or Risks followed by === / ---
        desired_header_regexp = "^(?:\\s*#+\\s*#{section_title}.*|\\s*#{section_title}.*\\n\\s*(?:-{2,}|={2,}))\\n"
        content_regexp = '([\W\w]*?)' # capture all section content, including new lines, but not next header
        next_header_regexp = '(?=^(?:\s*#+|.*\n\s*(?:-{2,}|={2,}\s*\n))|\z)'

        text[/#{desired_header_regexp}#{content_regexp}#{next_header_regexp}/i, 1]
      end
    end
  end

  class << self
    def cli(argv)
      parse_cli_options! argv
      token = fetch_token
      puts risks(*argv, token)
      0
    end

    private

    def risks(repo, diff, token)
      compare = http_get "/repos/#{repo}/compare/#{diff}", token

      pulls = parallel(compare.fetch(:commits), threads: 10) do |commit|
        http_get "/repos/#{repo}/commits/#{commit.fetch(:sha)}/pulls", token
      end.flatten(1).uniq

      pulls.flat_map do |pull|
        if risks = RiskParser.parse(pull.fetch(:body))
          risks
        else
          ["- missing risks from [#{pull.fetch(:number)}](#{pull.fetch(:html_url)})"]
        end
      end
    end

    def parse_cli_options!(argv)
      parser = OptionParser.new do |p|
        p.banner = <<~BANNER
          Collects Risk section from all merged PRs over a given commit range.
          Your github token needs to be available as `GITHUB_TOKEN` env var or `git config github.token`.

          Usage:
              risk-summary zendesk/samson v3240...v3250

          Options:
        BANNER
        p.on("-h", "--help", "Show this.") do
          puts p
          exit 0
        end
        p.on("-v", "--version", "Show Version") do
          puts VERSION
          exit 0
        end
      end
      parser.parse!(argv)

      if argv.size != 2
        puts parser
        exit 1
      end
    end

    def fetch_token
      ENV["GITHUB_TOKEN"] ||
        token_from_gitconfig ||
        raise("Unable to find github token in GITHUB_TOKEN env var or git config github.token")
    end

    def token_from_gitconfig
      result = `git config github.token`.chomp
      result if $?.success?
    end

    def http_get(path, token)
      url = "https://api.github.com#{path}"
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "token #{token}"
      req["Accept"] = "application/vnd.github.groot-preview+json" # for /pulls requests
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      raise "Bad response from #{url}:\n#{res.code}\n#{res.body}" unless res.code == "200"
      JSON.parse(res.body, symbolize_names: true)
    end

    def parallel(items, threads:)
      results = Array.new(items.size)
      items = items.each_with_index.to_a

      Array.new([threads, items.size].min) do
        Thread.new do
          loop do
            item, index = items.pop
            break unless index
            results[index] = yield item
          end
        end
      end.each(&:join)

      results
    end
  end
end
