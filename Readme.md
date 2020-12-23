<!-- keep in sync with bundle exec ./bin/risk-summary --help -->
Collects Risk section from all merged PRs over a given commit range.

Your github token needs to be available as `GITHUB_TOKEN` env var or `git config github.token`.

```bash
gem install risk-summary
risk-summary v11..v20
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
