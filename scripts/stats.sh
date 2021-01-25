#! /bin/bash
total=$(cat examples/output.log | wc -l)
quick=$(jq -c '. | select(.gn_quick == true)' examples/output.log | wc -l)
riot=$(jq -c '. | select(.gn_riot == true)' examples/output.log | wc -l)
bogon=$(jq -c '. | select(.gn_bogon == true)' examples/output.log | wc -l)
invalid=$(jq -c '. | select(.gn_invalid == true)' examples/output.log | wc -l)
noise_percent=$(echo "scale=4; $quick/$total" | bc -l)
riot_percent=$(echo "scale=4; $riot/$total" | bc -l)

echo "--Line Counts--"
echo "Total: $total"
echo "Noise: $quick"
echo "RIOT:  $riot"
echo "--Percentages--"
echo "Noise:    $noise_percent"
echo "RIOT:     $riot_percent"
