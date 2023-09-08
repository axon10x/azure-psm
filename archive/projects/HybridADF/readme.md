#### Hybrid Azure Data Factory (ADF) Deployment

##### On Premise Deployment

In the /onprem folder, the deploy.sh script will deploy an environment in Azure that simulates an on-premise environment, specifically:
* A database server VM simulating a reference data source
* A database server VM simulating a transactional data source
* Two host server VMs where the ADF Self-Hosted Integration Runtime (SHIR) can be installed and run (why two SHIR host VMs? To show HA deployment)

Two separate data sources (reference and transactional) are deployed for a more realistic overall pipeline than just using one single data source. Use the scripts for ref and tx databases (make sure to run the ref script on the ref data source and the tx script on the tx data source!) in the sql/ folder, or provide your own if preferred.

##### Azure Deployment

In the /azure folder, the deploy.sh script will deploy an environment in Azure that includes:
* Azure storage account and containers for data staging and other storage needs
* Azure SQL database instances for reference and transactional data (staging and final)
* Azure Data Factory instance with a self-hosted integration runtime and four pipelines: full and incremental reference data, and full and incremental transactional data

This deployment uses Azure Service Principals to authenticate ADF to Azure Storage, and to Azure SQL Databases. As Service Principals are created in an Azure Active Directory tenant, an Azure AD account is required as the Azure SQL server administrative account, and you should connect to Azure SQL using the credential you specify for this purpose in deploy.sh (see `azure_sql_server_admin_aad_display_name` and `azure_sql_server_admin_aad_principal_id`), so that you can run the SQL statements that add the Azure Service Principal to the Azure SQL databases. This eliminates the need for SQL authentication against the Azure SQL databases.

(Note that SQL authentication is used for the stand-in on-premise environment. You can replace with a supported authentication mechanism for on-premise resources.)

##### How to deploy

1. Open a bash prompt. Ensure you have the latest Azure CLI installed. Login to Azure using `az login`. Ensure you set the correct subscription to default (if you have more than one subscription).
2. Deploy the stand-in/simulated on-premise environment.
  * Edit ./onprem/deploy.sh. You will need to set several variable values (minimally, replace all occurences of the `###PROVIDE###` token in the variables section).
  * Run ./onprem/deploy.sh. This will take several minutes. Fix any errors and re-run as needed.
  * Edit ./onprem/sql/ref-db.sql and ./onprem/sql/tx-db.sql as needed.
    * NOTE!!! These two database scripts specify a physical location for database files! You MUST provide correct values here, appropriate for the database VMs you are deploying. The provided scripts assume an F:\ drive is available. If you will not provision data disks or use a different letter than F:\, change the data/log file paths to appropriate values for your environment.
  * When the deploy script completes, you should be able to connect to all the on-prem VMs via Remote Desktop Protocol (RDP). If not, you have a network or other issue; fix it before continuing.
  * RDP to the database VMs. As written, this deployment creates one database VM for reference data, and one database VM for transactional data. Do the following on each of these database VMs.
    * Open up port 1433 in the Windows Firewall so that ADF can connect to SQL Server.
    * If you left the VM ARM templates unchanged, then you must create and format an F: drive on the data disk created by the ARM template. The SQL scripts expect an F: drive. You must also provide the root path specified in the SQL scripts, i.e. \MSSQL\DATA\ or whatever you specify. (This is a good opportunity for further automation.)
    * Install your preferred SQL Server management tool, or use sqlcmd if you are comfortable running a SQL script at the command line.
    * Connect to the local SQL Server instance using the SQL Server management tool.
    * Update the local SQL Server's security settings to permit both SQL as well as Windows login. The ADF linked data sources assume SQL authentication.
    * On the reference data VM, run the ./onprem/sql/ref-db.sql script to create the database and database objects. Then run the ./onprem/sql/ref-db-initial-data.sql script to create some synthetic data.
    * On the transactional data VM, run the ./onprem/sql/tx-db.sql script to create the database and database objects. Then run the ./onprem/sql/tx-db-initial-data.sql script to create some synthetic data.
    * Verify database installation as needed. You can then disconnect from the database VMs.
3. Deploy the Azure environment.
  * Edit ./azure/deploy.sh. You will need to set several variable values (minimally, replace all occurences of the `###PROVIDE###` token in the variables section).
  * Run ./azure/deploy.sh.
    * Note that the script echoes some variables to the console. You may want to note, for example, the service principal password (and other info) as the service principal password CANNOT be retrieved after creation!
  * This script will end with several steps echoed to the console, which YOU need to take to complete this deployment. They are as follows:
    * Connect to the newly created Azure SQL databases, using the AAD credentials you specified as Azure SQL server administrator. On each database, run the SQL commands output to the console. These commands add the service principal (that ADF will use) to the database, and to appropriate roles in the database.
    * Now run the ADF script, step 1. The exact command line will be output to the console for you. This script creates the ADF with only a SHIR; no other ADF objects are created yet.
    * You now need to retrieve the new ADF SHIR authentication key, and then configure your on-premise SHIR host node(s). See below for how to do that. Ensure successful node connection to the ADF SHIR before continuing.
    * Now run the ADF script, step 2. Again, the exact command line will be output to the console for you. This script creates all remaining ADF artifacts.
    * Now run the Logic Apps script indicated at the console after running ./azure/deploy.sh. Again, the exact command line will be output to the console for you, and the corresponding .sh file will be automatically generated. This script generates a service principal-authenticated API Connection to Azure Data Factory, and a Logic App that uses this connection to start an ADF pipeline.


##### How to configure the on-premise nodes for the Azure Data Factory Self-Hosted Integration Runtime (SHIR)

  * Note: two on-premise SHIR node host VMs are deployed to simulate a Highly Available (HA) environment. Perform the same VM configuration steps listed below on both the host VMs.
  * Obtain the Azure Data Factory authentication key for the SHIR(s) on the host VM(s) using either of these two methods:
    * Using the Azure portal: follow instructions at https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime
    * Programmatically: follow instructions at https://docs.microsoft.com/powershell/azure/new-azureps-module-az to install Powershell Core and the new Azure Powershell Az module, then follow the instructions at https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime#high-level-steps-to-install-a-self-hosted-ir
      * Using Powershell Core/Az cmdlets: `Connect-AzAccount` followed by `Get-AzDataFactoryV2IntegrationRuntimeKey -ResourceGroupName ###PROVIDE### -DataFactoryName ###PROVIDE### -Name ###PROVIDE###` (substitute correct values for ###PROVIDE### token)
  * RDP to the host VM (remember, do these steps for each host VM)
    * Go to https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime and download/install the Self-Hosted Integration Runtime on the host VM. Enable intranet communication so the SHIR nodes can communicate with each other (important for HA).
    * At the end of setup, you will be asked to register the newly installed SHIR by entering the ADF authentication key you obtained in the previous step.
      * Note: to associate an _existing_ SHIR node installation to a new ADF, or to programmatically associate a SHIR node to new ADF, see https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime and https://github.com/MicrosoftDocs/azure-docs/issues/29819
        * (You do NOT need to do this for a new SHIR installation. This is only for EXISTING installations you need to associate with a different ADF.)
        * On the SHIR node host VM, open a command prompt and run the following: 
        * `"C:\Program Files\Microsoft Integration Runtime\3.0\Shared\dmgcmd.exe" -Key [AuthenticationKey retrieved in previous step]`
        * `net stop DIAHostService`
        * `net start DIAHostService`
    * Now start the newly installed Microsoft Integration Runtime Configuration Manager and verify the node is successfully connected to ADF - also verify this in the ADF Author and Manage portal. Find the Self-Hosted Integration Runtime there, and inspect its Nodes.

##### Notes

When exporting an ADF template from the ADF authoring portal, some editing is necessary/recommended to make the template more generic, and able to pass ARM validation (e.g. `az group deployment validate`).

* Fix parameters by correcting metadata attributes from a string to a JSON block (see the template in this repo)

##### References

ARM template docs: https://docs.microsoft.com/azure/templates/
ARM ADF: https://docs.microsoft.com/azure/templates/microsoft.datafactory/allversions

AZ CLI docs: https://docs.microsoft.com/cli/azure

ADF SHIR: https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime

SQL Service Principal authentication:
https://docs.microsoft.com/azure/data-factory/connector-azure-sql-database#service-principal-authentication
https://docs.microsoft.com/azure/sql-database/sql-database-aad-authentication-configure#create-contained-database-users-in-your-database-mapped-to-azure-ad-identities

Storage Service Principal authentication:
https://docs.microsoft.com/azure/data-factory/connector-azure-blob-storage#service-principal-authentication
https://docs.microsoft.com/azure/storage/common/storage-auth-aad
https://docs.microsoft.com/azure/storage/common/storage-auth-aad-rbac-cli
