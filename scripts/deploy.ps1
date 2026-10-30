param(
    [Parameter(Mandatory=$true)][ValidateSet('v1','v2','v3')][string]$Version,
    [Parameter(Mandatory=$true)][string]$Image,
    [string]$BuildId = 'manual'
)
$ErrorActionPreference = 'Stop'
$port = @{v1=30081;v2=30082;v3=30083}[$Version]
$template = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../k8s/app.yaml') -Raw
$manifest = $template.Replace('__VERSION__',$Version).Replace('__IMAGE__',$Image).Replace('__PORT__',"$port").Replace('__BUILD__',$BuildId)
$manifest | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'Kubernetes apply failed' }
kubectl rollout status "deployment/social-app-$Version" -n agile-social --timeout=180s
if ($LASTEXITCODE -ne 0) { throw 'Deployment did not become ready' }
kubectl get deployment,service,pvc -n agile-social
if ($LASTEXITCODE -ne 0) { throw 'Could not read deployment status' }
