#!/bin/bash

artifact_id="002-004"
resource_group_name="ams2"
azure_region="eastus"
ams_acct_name="pzams2"
storage_acct_name="$ams_acct_name""sa"
stream_ingest_container_name="$artifact_id"
stream_endpoint_name="default"
scale_units=1
source_ip_address="75.68.47.183"
stream_ingest_access_token="FooFooFooWoo2019"
live_event_name="le-""$artifact_id"
stream_ingest_protocol=RTMP
stream_ingest_asset_name="as-""$artifact_id"
live_output_name="lou-""$artifact_id"
live_output_manifest_name="$live_output_name""-manifest"
stream_locator_name="slo-""$artifact_id"
stream_policy_name=Predefined_DownloadAndClearStreaming
stream_archive_window_length=PT25H

# Create new resource group
echo "Creating Resource Group"
az group create -n $resource_group_name -l $azure_region

# Create storage account for AMS use
echo "Creating Storage Account"
az storage account create -g $resource_group_name -n $storage_acct_name -l $azure_region --kind StorageV2 --sku Standard_LRS

# Create AMS account
echo "Creating AMS Account"
az ams account create -n $ams_acct_name -l $azure_region -g $resource_group_name --storage-account $storage_acct_name

# Wait for streaming endpoint provisioning
echo "ZZZZZ..... Sleeping 60s to wait for streaming endpoint provisioning"
sleep 60s

# List streaming endpoints
echo "List Streaming Endpoints"
az ams streaming-endpoint list -g $resource_group_name -a $ams_acct_name

# Scale streaming endpoint
echo "Scale streaming endpoint"
az ams streaming-endpoint scale -a $ams_acct_name -n $stream_endpoint_name -g $resource_group_name --scale-units $scale_units

# Start streaming endpoint
echo "Start streaming endpoint"
az ams streaming-endpoint start -a $ams_acct_name -n $stream_endpoint_name -g $resource_group_name

# Create live event with auto-start, no encoding, specified token, and vanity URL
echo "Create Live Event with Auto-Start"
az ams live-event create -a $ams_acct_name --ips $source_ip_address -n $live_event_name -g $resource_group_name --streaming-protocol $stream_ingest_protocol --access-token $stream_ingest_access_token --auto-start --encoding-type None --vanity-url true

# Show live event details, including RTMP(S) ingest URLs
echo "Show Live Event"
az ams live-event show -n $live_event_name -g $resource_group_name -a $ams_acct_name

# Stop live event - e.g. to test ingest URL consistency
# echo "Stop Live Event"
# az ams live-event stop -a $ams_acct_name -g $resource_group_name -n $live_event_name

# Start live event - e.g. to test ingest URL consistency
# echo "Start Live Event"
# az ams live-event start -a $ams_acct_name -g $resource_group_name -n $live_event_name

# Create asset for stream storage
echo "Create Asset"
az ams asset create -a $ams_acct_name -g $resource_group_name -n $stream_ingest_asset_name --container $stream_ingest_container_name --storage-account $storage_acct_name

# Create a live output associated with the live event and asset
echo "Create Live Output"
az ams live-output create -a $ams_acct_name -g $resource_group_name -n $live_output_name --live-event-name $live_event_name --archive-window-length $stream_archive_window_length --asset-name $stream_ingest_asset_name --manifest-name $live_output_manifest_name

# Create a streaming locator
echo "Create Streaming Locator"
az ams streaming-locator create -a $ams_acct_name -g $resource_group_name -n $stream_locator_name --asset-name $stream_ingest_asset_name --streaming-policy-name $stream_policy_name

# List streaming locators
echo "List streaming locators"
az ams streaming-locator list -a $ams_acct_name -g $resource_group_name

# Get streaming locator info
echo "Show Streaming Locator"
az ams streaming-locator show -a $ams_acct_name -g $resource_group_name -n $stream_locator_name

# List all paths for the streaming locator
echo "Show Streaming Locator paths"
az ams streaming-locator get-paths -a $ams_acct_name -g $resource_group_name -n $stream_locator_name

# Concatenate scheme (https://), live event hostname, and one of the paths to get a streaming player source URL