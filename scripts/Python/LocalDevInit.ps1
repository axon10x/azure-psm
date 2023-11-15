$env:ADAL_PYTHON_SSL_NO_VERIFY = '1'
$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = '1'

. ./scripts/PythonGeneral.ps1
. ./scripts/PythonVirtualEnv.ps1

$pythonVersion = Get-CurrentPythonVersion -IncludePunctuation $false
$VEnvPath = "venv" + $pythonVersion

New-VirtualEnvironment -VEnvPath $VEnvPath
Enter-VirtualEnvironment -VEnvPath $VEnvPath

Invoke-PipUpgrade

$reqFileName = "requirements.txt"
Invoke-PipInstallRequirements -RequirementsFilePath $reqFileName

# Azurite storage emulator connection string to env var
$env:DevStoreConnectionString="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
