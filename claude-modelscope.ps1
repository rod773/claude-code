param(
  [string]$Model = "deepseek-ai/DeepSeek-V4-Flash",
  [string]$ApiKey = "",
  [string]$BaseUrl = "https://api-inference.modelscope.ai"
)

if (-not $ApiKey) {
  $ApiKey = Read-Host "Enter your ModelScope API key (ms-...)"
}

$env:ANTHROPIC_BASE_URL = $BaseUrl
$env:ANTHROPIC_API_KEY = $ApiKey
$env:ANTHROPIC_MODEL = $Model

Write-Host "ModelScope: $Model" -ForegroundColor Cyan
Write-Host "Endpoint: $BaseUrl" -ForegroundColor Cyan
& claude @args
