#!/bin/bash

resource_group_name=$1
location=$2

autoshutdown_template_file="../autoshutdown.template.json"
autoshutdown_time="2300"
autoshutdown_timezone="UTC"
autoshutdown_notification_state="Enabled"
autoshutdown_notification_minutes_before=15
autoshutdown_notification_webhook_url="https://outlook.office.com/webhook/30e5b36a-fbf1-4704-8d54-f9a3e5aafa73@72f988bf-86f1-41af-91ab-2d7cd011db47/IncomingWebhook/88349508dacd45a5b46b19e704b1f6bf/b995e2c1-f7d9-41c8-a865-c5a7213150b8"
autoshutdown_notification_email="paelaz@microsoft.com"
autoshutdown_notification_locale="en"

vm_names="$(az vm list -g $resource_group_name -o tsv --query [].name)"

for vm_name in $vm_names
do
	echo "Configure VM Auto-Shutdown for ""$vm_name"
	schedule_name="shutdown-computevm-""$vm_name"
	az group deployment create -g "$resource_group_name" -n "$schedule_name" --template-file "$autoshutdown_template_file" --no-wait --parameters \
		location="$location" vm_name="$vm_name" shutdown_timezone="$autoshutdown_timezone" shutdown_time="$autoshutdown_time" notification_state="$autoshutdown_notification_state" \
		notification_web_hook_url="$autoshutdown_notification_webhook_url" notification_email="$autoshutdown_notification_email" \
		notification_minutes_before="$autoshutdown_notification_minutes_before" notification_locale="$autoshutdown_notification_locale"
done

