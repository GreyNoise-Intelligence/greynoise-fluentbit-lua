![main](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/workflows/.github/workflows/main.yml/badge.svg)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


# GreyNoise FluentBit Lua Prototype
This is a prototype filter plugin for [FluentBit](https://fluentbit.io/) which uses the GreyNoise API to drop or de-prioritize records in order

# Getting Started

These instructions will cover usage information and for the docker container

### Prerequisities

In order to run this container you'll need docker installed.

* [Windows](https://docs.docker.com/windows/started)
* [OS X](https://docs.docker.com/mac/started/)
* [Linux](https://docs.docker.com/linux/started/)

In order to run `make stats` you will need `jq` installed

* [JQ](https://stedolan.github.io/jq/download/)

## GreyNoise Sign-Up
1. [Sign-Up for GreyNoise](https://viz.greynoise.io/signup/)
1. Copy `.env_example` to `.env`
1. Copy your GreyNoise API key from the `Account` section in the top right corner
1. Replace the `<REPLACE_ME>` in `.env` with your API key
1. Create a directory for your configs `mkdir conf`
1. Add your FluentBit configs and parsers to `conf/`

## Docker
### Usage

#### Container Parameters

```shell
docker run --env-file .env -it -p 2020:2020 -v $(PWD):/app greynoise/greynoise-fluentbit-lua:latest -c conf/myconfig.conf
```

#### Environment Variables (required)

This fiter uses environment variables to configure the ability to drop records directly in the filter. If you do not wish to drop records in the filter you can use the FluentBit [Rewrite Tag](https://docs.fluentbit.io/manual/pipeline/filters/rewrite-tag) filter to construct rules which re-tag records based on the appended metadata so they can be dropped or routed appropriately.

* `GREYNOISE_API_KEY` - GreyNoise API key to use for HTTP requests.
* `GREYNOISE_IP_FIELD` - Named field from the FluentBit parser to use for IP lookups.
* `GREYNOISE_LUA_LOG_LEVEL` - Lua logging level (info/error/warning/debug)
* `GREYNOISE_LUA_CACHE_SIZE` - The number of IP records to cache in-memory before overwriting.
* `GREYNOISE_DROP_RIOT_IN_FILTER` - Drop records directly in the filter that return true for the `/v2/riot` endpoint.
* `GREYNOISE_DROP_QUICK_IN_FILTER` - Drop records directly in the filter that return true for `/v2/noise/quick` endpoint.
* `GREYNOISE_DROP_BOGON_IN_FILTER` - Drop records directly in the filter that are for bogon address space.
* `GREYNOISE_DROP_INVALID_IN_FILTER` - Drop records directly in the filter that do not contain a valid IPv4 address.

#### Volumes

* `/app` - Core working directory (mounted from the base repo folder)

# Sample Data Testing

## Run Example 1 Dummy Data
1. Copy `.env_example` to `.env`
1. Copy your GreyNoise API key from the `Account` section in the top right corner
1. Replace the `<REPLACE_ME>` in `.env` with your API key
1. Run `make build`
1. Run `make run`

## Run Example 2 Linux Auth.log
1. Copy a Linux `auth.log` file to the `examples` directory
1. Run `make run-tail`

## Monitoring Run Metrics
1. Run `curl -s http://127.0.0.1:2020/api/v1/metrics | jq` while fluentbit is running.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the
[tags on this repository](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/tags).

## Authors

* **Matt Lehman** - *Initial work* - [Obsecurus](https://github.com/Obsecurus)

See also the list of [contributors](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

* Eduardo Silva (https://github.com/edsiper) - guidance on FluentBit Lua optimizations
* leite (https://github.com/leite) - `lua/iputil.lua` module
* rxi (https://github.com/rxi) - `lua/log.lua` module