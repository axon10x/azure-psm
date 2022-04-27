#!/bin/bash

artifact_id="002-004"
resource_group_name="ams2"
azure_region="eastus"
ams_acct_name="pzams2"
storage_acct_name="$ams_acct_name""sa"
videos_transform_name="tfm-""$artifact_id"
videos_transform_preset="H264MultipleBitrate1080p"
videos_job_name="job-""$artifact_id"
video_files_asset_name="$stream_ingest_asset_name""-videos"
video_files_container_name=$video_files_asset_name
video_files_job_output_asset_name="$video_files_asset_name='"   # This works though it looks like it shouldn't. https://docs.microsoft.com/en-us/cli/azure/ams/job?view=azure-cli-latest#az-ams-job-start

# Output to MP4 files for on-demand download, archiving etc.
# Scale MRU - https://docs.microsoft.com/en-us/azure/media-services/latest/media-reserved-units-cli-how-to
az ams account mru show -n $ams_acct_name -g $resource_group_name

az ams account mru set -n $ams_acct_name -g $resource_group_name --count 10 --type S3

az ams asset create -a $ams_acct_name -g $resource_group_name -n $video_files_asset_name --container $video_files_container_name --storage-account $storage_acct_name

az ams transform create -a $ams_acct_name -g $resource_group_name -n $videos_transform_name --preset $videos_transform_preset --relative-priority "High"

az ams job start -a $ams_acct_name -g $resource_group_name -n $videos_job_name --transform-name $videos_transform_name --input-asset-name $stream_ingest_asset_name --output-assets $video_files_job_output_asset_name

# Repeat this until job is in "Finished" state. Expect n-nn minutes (depends on video length etc.)
az ams job show -a $ams_acct_name -g $resource_group_name -n $videos_job_name --transform-name $videos_transform_name

# Wait for job... 15 minutes
echo "ZZZZZ....."
sleep 900s

# When job in "Finished" state scale MRUs back down for cost reduction
az ams account mru set -n $ams_acct_name -g $resource_group_name --count 0 --type S1
