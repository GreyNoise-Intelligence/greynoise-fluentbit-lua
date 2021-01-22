#! /bin/bash
set -a
source ./.env
set +a
/opt/td-agent-bit/bin/td-agent-bit -c ${FB_CONF_FILE}
