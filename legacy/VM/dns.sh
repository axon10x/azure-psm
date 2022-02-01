#!/bin/bash

az network private-dns zone create -g "infradns" -n "private.pz.info"

az network private-dns link vnet create -g "infradns" -n "i1vnet1_dns_link" -z "private.pz.info" -v "/subscriptions/e61e4c75-268b-4c94-ad48-237aa3231481/resourceGroups/infrai1/providers/Microsoft.Network/virtualNetworks/i1vnet1" -e true

az network private-dns link vnet create -g "infradns" -n "i2vnet1_dns_link" -z "private.pz.info" -v "/subscriptions/e61e4c75-268b-4c94-ad48-237aa3231481/resourceGroups/infrai2/providers/Microsoft.Network/virtualNetworks/i2vnet1" -e true
