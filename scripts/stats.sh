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

get_fb_stats () {
    curl -s http://127.0.0.1:2020/api/v1/metrics | jq '.input'
}

res=$(get_fb_stats)
records=$(echo $res | jq '.rewrite_input.records')
noise=$(echo $res | jq '.gn_noise.records')
riot=$(echo $res | jq '.gn_noise.riot')
bogon=$(echo $res | jq '.gn_noise.bogon')
invalid=$(echo $res | jq '.gn_noise.invalid')

total_invalid=$(echo "scale=4; $bogon + $invalid" | bc -l)
total_noise=$(echo "scale=4; $noise + $riot" | bc -l)
noise_percentage=$(echo "scale=2; $total_noise/$records" | bc -l | cut -c 2-)

echo "GreyNoise Fluentbit Filter Stats"
echo "================================"
echo ""
echo "Total Records:       ${records}"
echo "All Noise Records:   ${total_noise} (Noise, RIOT)"
echo "All Invalid Records: ${total_invalid}    (Bogon, Invalid)"
echo "Noise Percentage:    ${noise_percentage}%"