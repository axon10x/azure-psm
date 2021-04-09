#!/bin/bash

# Lists all VMs' name and license type. Windows_Server indicates AHUB benefit used.
az vm list -o tsv --query [].[name,licenseType]