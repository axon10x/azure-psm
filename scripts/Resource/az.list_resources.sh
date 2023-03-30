#!/bin/bash

resource_group_name=""
infix=""

qtext="[?starts_with(name, '""$infix""')].[name]"

resources="$(az resource list -g $resource_group_name -o tsv --query "$qtext")"

for resource in $resources
do
    echo $resource
done
