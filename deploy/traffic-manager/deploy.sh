#!/bin/bash

subscriptionId="$(az account show -o tsv --query 'id')"
location="eastus2" # TM Profile is global, but need location for resource group and where TM resource will be located
resourceGroupName="tm"

tmProfileName="pz-tm"
trafficRoutingMethod="Weighted"

templateTrafficManagerProfile="../../template/net.traffic-manager.profile.json"
templateTrafficManagerEndpoint="../../template/net.traffic-manager.external-endpoint.json"

echo "Create Resource Group"
az group create --subscription "$subscriptionId" -l "$location" -n "$resourceGroupName" --verbose

echo "Create Traffic Manager Profile"
az deployment group create --subscription "$subscriptionId" -n "TMP" --verbose \
	-g "$resourceGroupName" --template-file "$templateTrafficManagerProfile" \
	--parameters \
	trafficManagerProfileName="$tmProfileName" \
	trafficRoutingMethod="$trafficRoutingMethod" \
	dnsTtl=0 \
	protocol="HTTPS" \
	port=443

echo "Create Traffic Manager Profile Endpoint eastus2"
az deployment group create --subscription "$subscriptionId" -n "TME" --verbose \
	-g "$resourceGroupName" --template-file "$templateTrafficManagerEndpoint" \
	--parameters \
	trafficManagerProfileName="$tmProfileName" \
	endpointName="pz-asb-eus2" \
	endpointTarget="pz-asb-eus2.servicebus.windows.net" \
	weight=1 \
	priority=0

echo "Create Traffic Manager Profile Endpoint centralus"
az deployment group create --subscription "$subscriptionId" -n "TME" --verbose \
	-g "$resourceGroupName" --template-file "$templateTrafficManagerEndpoint" \
	--parameters \
	trafficManagerProfileName="$tmProfileName" \
	endpointName="pz-asb-cus" \
	endpointTarget="pz-asb-cus.servicebus.windows.net" \
	weight=1 \
	priority=0
