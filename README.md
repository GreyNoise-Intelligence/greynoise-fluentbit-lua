# GreyNoise FluentBit Lua Prototype

# Getting Started w/ Dummy Data
1. Sign-Up for GreyNoise `https://viz.greynoise.io/signup/`
1. Copy `.env_example` to `.env`
1. Copy your GreyNoise API key from the `Account` section in the top right corner
1. Replace the `<REPLACE_ME>` in `.env` with your API key
1. Run `make build`
1. Run `make run` (for generated data)

# Run w/ Linux Auth Logs
1. Copy an `auth.log` file to the base repo directory
1. Run `make run-tail`

# Monitoring Run Metrics
1. Run `curl -s http://127.0.0.1:2020/api/v1/metrics | jq`

# Customizing
1.

# TODO
1. Add busted tests
1. Add sample JSON log file for testing
1. Fix Dockerfile for entrypoint/prep for use as a community image
1. Finish README.md (explain drops, rewrites, etc.)
1. Fix licenses
1. Build demo environment w/ Splunk