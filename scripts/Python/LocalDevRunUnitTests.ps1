# Run LocalDevInit.ps1 before running this

. ./scripts/PythonGeneral.ps1
. ./scripts/PythonVirtualEnv.ps1

$pythonVersion = Get-CurrentPythonVersion -IncludePunctuation $false
$VEnvPath = "venv" + $pythonVersion

Enter-VirtualEnvironment -VEnvPath $VEnvPath

$expr = "python -m pytest tests --doctest-modules --junitxml=test-results/junit/test-results.xml --cov=. --cov-report=xml --cov-report=html"
Invoke-Expression $expr
