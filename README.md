[![main](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/workflows/Build/badge.svg)](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/actions?query=workflow%3ABuild)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


# GreyNoise Fluent Bit Lua Filter
This is a prototype [Fluent Bit](https://fluentbit.io/) container using a [filter plugin](https://docs.fluentbit.io/manual/concepts/data-pipeline/filter) which calls the GreyNoise API to drop, re-route, or enrich records. This specific filter leverages the [Fluent Bit Lua script filter](https://docs.fluentbit.io/manual/pipeline/filters/lua).


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

## Docker
### Usage

#### Container Parameters

```shell
docker run --env-file .env -it -p 2020:2020 -v $(PWD):/app greynoise/greynoise-fluentbit-lua:latest -c /app/conf/myconfig.conf
```

#### Environment Variables (required)

* `GREYNOISE_API_KEY` - GreyNoise API key to use for HTTP requests.
* `GREYNOISE_IP_FIELD` - Named field from the Fluent Bit parser to use for IP lookups.
* `GREYNOISE_LUA_LOG_LEVEL` - Lua logging level (info/error/warning/debug)
* `GREYNOISE_LUA_CACHE_SIZE` - The number of IP records to cache in-memory before overwriting.

#### Volumes

* `/app` - Core working directory (mounted from the base repo folder)

# Sample Data Testing
The sample data tests are meant to be run from the repo base folder.

## Example 1 - Dummy Data
[`conf/dummy.conf`](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/conf/dummy.conf)

This example just generates the same JSON line over and over.
1. Copy `.env_example` to `.env`
1. Copy your GreyNoise API key from the `Account` section in the top right corner
1. Replace the `<REPLACE_ME>` in `.env` with your API key
1. Run `make build`
1. Run `make run`

## Example 2 - Auth.log
[`conf/tail.conf`](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/conf/tail.conf)

This example watches reads a log file in and watches for new lines.
1. Copy a Linux `auth.log` file to the `examples` directory
1. Run `make run-tail`
1. Run `make stats` in another terminal to see metrics

## Example 3 - Auth.log With RewriteTag Rules
[`conf/rewrite.conf`](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/conf/rewrite.conf)

This is the same as #2 except this leverages [rewrite_tag](https://docs.fluentbit.io/manual/pipeline/filters/rewrite-tag) filter to drop records.
This config drops invalid IPv4 records, bogon address space, GreyNoise RIOT records, and GreyNoise Quick records.
1. Copy a Linux `auth.log` file to the `examples` directory
1. Run `make run-rewrite`
1. Run `make stats` in another terminal to see metrics (note the drop rates)

# Running in your environment
1. Create a directory for your configs `mkdir conf`
1. Add your Fluent Bit configs and parsers to `conf/`
1. Create a directory for your outputs `mkdir output`
1. You should now have a directory tree that looks something like the following:
    ```shell
    conf/
        parser.conf
        myconfig.conf
    output/
    .env
    ```
1. Run the docker command
```shell
docker run --env-file .env -it -p 2020:2020 -v $(PWD):/app greynoise/greynoise-fluentbit-lua:latest -c /app/conf/myconfig.conf
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the
[tags on this repository](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/tags).

## Authors

* **Matt Lehman** - *Initial work* - [Obsecurus](https://github.com/Obsecurus)

See also the list of [contributors](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/GreyNoise-Intelligence/greynoise-fluentbit-lua/LICENSE.md) file for details.

## Acknowledgments

* Eduardo Silva (https://github.com/edsiper) - guidance on Fluent Bit Lua optimizations
* leite (https://github.com/leite) - `greynoise/src/iputil.lua` module
* rxi (https://github.com/rxi) - `greynoise/src/log.lua` module

## Links

* [GreyNoise.io](https://greynoise.io)
* [GreyNoise Terms](https://greynoise.io/terms)
* [GreyNoise Developer Portal](https://developer.greynoise.io)

## Contact Us

Have any questions or comments about GreyNoise?  Contact us at [hello@greynoise.io](mailto:hello@greynoise.io)