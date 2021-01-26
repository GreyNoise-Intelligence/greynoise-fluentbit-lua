Contributing to GreyNoise Fluentbit Lua
===========================

Welcome! Here you can find guidance on the
best way to contribute to this FluentBit filter.

Bugs reports and feature requests
---------------------------------

We are happy to receive feature request or bug reports on the
GitHub [issue tracker].

A bug report is most useful if it gives detailed, *reproducible*
instructions. Additionally, it should include

  * the fluentbit version.
  * the exact docker arguments used.
  * the exact fluentbit config used.
  * the output received.
  * the output you expected instead.

This will allow us to help you more quickly. A template is included via `.github/ISSUE_TEMPLATE/bug.md` as well.

Pull requests
-------------

Whether small or large PRs are welcomed. PRs

All new/modified Lua code should have tests in the `greynoise/spec/` folder.

We currently test using Github Actions by calling `make test` which uses the Lua [Busted](https://olivinelabs.com/busted/) test harness. This can be modified here:

- *Github Actions*: tests are run in the latest ubuntu:20.04 Docker
  image. The config is in `.github/workflows/main.yml`.

Commits
-------

Please follow the usual guidelines for git commits: keep commits
atomic, self-contained, and add a brief but clear commit message.
This [guide](https://chris.beams.io/posts/git-commit/) by Chris
Beams is a good resource if you'd like to learn more.

However, don't fret over this too much. You can also just
accumulate commits without much thought for this rule. All commits in a PR can be squashed into a single commit upon merging. But
it is still appreciated if the commit message doesn't need to be rewritten.

[FluenBit Lua Filter]: https://docs.fluentbit.io/manual/pipeline/filters/lua
[Lua style guide]: https://github.com/hslua/lua-style-guide
