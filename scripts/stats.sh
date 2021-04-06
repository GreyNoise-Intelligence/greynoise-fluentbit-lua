#! /bin/bash
if ! command -v jq &> /dev/null
then
    echo "`jq` could not be found, please install `jq`"
    exit 1;
fi

if ! command -v curl &> /dev/null
then
    echo "`curl` could not be found, please install `curl`"
    exit 1;
fi

process_raw_log () {
    log=$1
    echo "## Stats for: $log"
    total=$(cat $log | wc -l)
    noise=$(jq -c '. | select(.gn_noise == true)' $log | wc -l)
    riot=$(jq -c '. | select(.gn_riot == true)' $log | wc -l)
    bogon=$(jq -c '. | select(.gn_bogon == true)' $log | wc -l)
    invalid=$(jq -c '. | select(.gn_invalid == true)' $log | wc -l)
    noise_percent=$(echo "scale=4; $noise/$total" | bc -l)
    riot_percent=$(echo "scale=4; $riot/$total" | bc -l)
    bogon_percent=$(echo "scale=4; $bogon/$total" | bc -l)
    invalid_percent=$(echo "scale=4; $invalid/$total" | bc -l)

    echo "--Line Counts--"
    echo "Total:    $total"
    echo "Noise:    $noise"
    echo "RIOT:     $riot"
    echo "Bogon:    $bogon"
    echo "Invalid:  $invalid"
    echo "--Percentages--"
    echo "Noise:    $noise_percent"
    echo "RIOT:     $riot_percent"
    echo "Bogon:    $bogon_percent"
    echo "Invalid:  $invalid_percent"
    printf "\n"
}

get_fb_stats () {
    curl -s http://127.0.0.1:2020/api/v1/metrics | jq '.input'
}


get_fb_stats
# for log in output/*; do
#     process_log $log
# done