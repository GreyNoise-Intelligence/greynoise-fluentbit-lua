#! /bin/bash

# Export all ENV vars
set -a
source .env
set +a

test()
{
    busted -C ./lua test.lua
}

shell()
{
    /bin/bash
}

run()
{
    /opt/td-agent-bit/bin/td-agent-bit -c ${FB_CONF_FILE}
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--test) test ;;
        -s|--shell) shell;;
        -r|--run) run ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
