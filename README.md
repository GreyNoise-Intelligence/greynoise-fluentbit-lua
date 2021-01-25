# GreyNoise FluentBit Lua Prototype
This is a prototype filter plugin for [FluentBit](https://fluentbit.io/).

# Getting Started

## GreyNoise Sign-Up
1. Sign-Up for GreyNoise `https://viz.greynoise.io/signup/`

## Run w/ Dummy Data
1. Copy `.env_example` to `.env`
1. Copy your GreyNoise API key from the `Account` section in the top right corner
1. Replace the `<REPLACE_ME>` in `.env` with your API key
1. Run `make build`
1. Run `make run`

## Run w/ Linux Auth Logs
1. Copy a Linux `auth.log` file to the base repo directory
1. Run `make run-tail`

## Monitoring Run Metrics
1. Run `curl -s http://127.0.0.1:2020/api/v1/metrics | jq`

# Customization

## Direct Filter Drops
This fiter uses environment variables to configure the ability to drop records directly in the filter. If you do not wish to drop records in the filter you can use the FluentBit [Rewrite Tag](https://docs.fluentbit.io/manual/pipeline/filters/rewrite-tag) filter to construct rules which re-tag records based on the appended metadata so they can be dropped or routed appropriately.

* **riot** - Drop records directly in the filter that return true for the  `/v2/riot` endpoint. `GREYNOISE_DROP_RIOT_IN_FILTER=true`
* **quick** - Drop records directly in the filter that return true for `/v2/noise/quick` endpoint. `GREYNOISE_DROP_QUICK_IN_FILTER=true`
* **bogon** - Drop records directly in the filter that are for bogon address space. `GREYNOISE_DROP_BOGON_IN_FILTER=true`
* **invalid** - Drop records directly in the filter that do not contain a valid IPv4 address. `GREYNOISE_DROP_INVALID_IN_FILTER=true`

# TODO
1. Fix licenses
1. Build demo environment w/ Splunk
1. Fix bad IP causing HTTP 500 that start with 0*.*.*.*?
