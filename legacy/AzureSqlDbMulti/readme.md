# Azure SQL DB Multi-Instance

## PLEASE NOTE

Summary disclaimer for this entire repo: https://github.com/plzm/azure. By using anything in this repo in any way, you agree to that disclaimer.

## Summary

This folder contains a deploy.sh script which has the following steps:

1. Deploy a storage account and blob container
2. Deploy a source Azure SQL database server, and a blank source Azure SQL Database
3. Import a sample database (Worldwide Importers) into the blank source database
4. Deploy a target Azure SQL database server, and a blank target Azure SQL Database
5. Export a bacpac from the source Azure SQL database and store it in the storage account and container created above
6. Import the bacpac to the existing target Azure SQL database
