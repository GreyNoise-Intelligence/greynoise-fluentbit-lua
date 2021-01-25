#! /bin/bash
set -a
source .env
set +a

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--test) test=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ $test ]]
then
    busted -C ./lua test.lua
    exit 1;
else
    /opt/td-agent-bit/bin/td-agent-bit -c ${FB_CONF_FILE}
fi


