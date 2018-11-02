#!/bin/bash

#edit the ports and jobs arrays
#pipe this to a json cleaner because it makes invalid json
#it is very suboptimal
#for example: https://gist.github.com/liftoff/ee7b81659673eca23cd9fc0d8b8e68b7

ports=(9100 9323)
jobs=(node docker)
#keep the above arrays in order as they pair with each other
range='127.0.0.0/24'
#generate config:
echo "["
#generate a chunk of the blob for each port as a logical grouping
#this is messy because we are tracking the values of the index and which index
#we are on for comparing to between the ports array and the jobs array
for port in "${!ports[@]}"; do
  echo "  {"
  echo "    \"targets\": ["
  #nmap each port separately and dump to a unique temp file
  tempfile=$(mktemp)
  nmap -p ${ports[port]} ${range} -oG "${tempfile}" >/dev/null 2>&1
  #grep for open ports only in output
  grep "${ports[port]}/open" < "${tempfile}" | while IFS= read -r line; do
    #for each open port, discover the hostname as determined by nmap
    host=$(echo "${line}" | cut -f1 -d\)|cut -f2 -d\( )
    #write config to file
    echo "      \"$host:${ports[port]}\","
  done
  echo "    ],"
  echo "    \"labels\": {"
  echo "      \"job\": \"${jobs[port]}\""
  echo "    },"
  echo "  },"
  rm -f "${tempfile}"
done
echo "]"
