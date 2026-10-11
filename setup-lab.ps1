[CmdletBinding()]
param(
    [switch]$CreateKindCluster,
    [string]$ClusterName = "accounts-api-lab"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
Set-Location -LiteralPath $Root

function Require-Command([string]$Name, [string]$InstallHint) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing '$Name'. $InstallHint"
    }
}

Require-Command "python" "Install Python 3 and reopen PowerShell."
Require-Command "conftest" "Install the Conftest CLI, then reopen PowerShell."

Write-Host "Running policy fixtures..." -ForegroundColor Cyan
python scripts/policy_smoke.py
if ($LASTEXITCODE -ne 0) { throw "Policy fixtures failed (exit $LASTEXITCODE)." }

Write-Host "Checking waiver expiry and required fields..." -ForegroundColor Cyan
python scripts/check_waivers.py
if ($LASTEXITCODE -ne 0) { throw "Waiver check failed (exit $LASTEXITCODE)." }

if (Get-Command kyverno -ErrorAction SilentlyContinue) {
    Write-Host "Running Kyverno admission-policy tests..." -ForegroundColor Cyan
    Push-Location (Join-Path $Root "k8s")
    try {
        kyverno test kyverno/kyverno-test.yaml
        if ($LASTEXITCODE -ne 0) { throw "Kyverno tests failed (exit $LASTEXITCODE)." }
    } finally { Pop-Location }
} else {
    Write-Host "Kyverno CLI not found; admission tests were skipped." -ForegroundColor Yellow
}

if ($CreateKindCluster) {
    Require-Command "docker" "Install and start Docker Desktop first."
    Require-Command "kind" "Install kind first."
    Require-Command "kubectl" "Install kubectl first."
    docker info *> $null
    if ($LASTEXITCODE -ne 0) { throw "Docker Desktop is installed but its engine is not running." }
    $clusters = kind get clusters
    if ($clusters -contains $ClusterName) { throw "A kind cluster named '$ClusterName' already exists. Choose another -ClusterName." }
    Write-Host "Creating local kind cluster '$ClusterName'..." -ForegroundColor Cyan
    kind create cluster --name $ClusterName
    if ($LASTEXITCODE -ne 0) { throw "kind cluster creation failed (exit $LASTEXITCODE)." }
    kubectl cluster-info --context "kind-$ClusterName"
    if ($LASTEXITCODE -ne 0) { throw "Cluster was created but kubectl could not reach it." }
    Write-Host "Cluster ready. No workload or AWS resources were deployed." -ForegroundColor Green
}

Write-Host "Lab checks completed." -ForegroundColor Green
