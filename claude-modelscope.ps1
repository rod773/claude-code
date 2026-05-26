param(
  [string]$Model = "deepseek-ai/DeepSeek-V4-Flash"
)

$env:ANTHROPIC_BASE_URL = "https://api-inference.modelscope.ai"
$env:ANTHROPIC_API_KEY = "YOUR_MODELSCOPE_KEY"
$env:ANTHROPIC_MODEL = $Model

Write-Host "ModelScope: $Model" -ForegroundColor Cyan
& claude @args
