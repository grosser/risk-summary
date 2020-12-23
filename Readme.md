<!-- keep in sync with bundle exec ./bin/risk-summary --help -->
Collects Risk section from all merged PRs over a given commit range.

Private repos: set a github token as `GITHUB_TOKEN` env var or `git config github.token` (also increases your api rate limit).

```bash
gem install risk-summary

risk-summary zendesk/samson v3248...v3250
- Low. Blue/Green naming could sneak into a k8s resource name unintentionally.
- missing risks from [3894](https://github.com/zendesk/samson/pull/3894)
```

TODO
====
- support token via cli argument
- support github enterprise with custom domain
- support gitlab
- support commit ranges with >250 commits [details](https://stackoverflow.com/questions/26925312/github-api-how-to-compare-2-commits)

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
![CI](https://github.com/grosser/risk-summary/workflows/CI/badge.svg)
[![coverage](https://img.shields.io/badge/coverage-100%25-success.svg)](https://github.com/grosser/single_cov)
