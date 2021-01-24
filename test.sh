#! /bin/bash
set -a
source .env
set +a
busted -C /app/lua test.lua