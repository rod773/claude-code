# Tutorial: Conectar OpenCode (Claude Code) con ModelScope API

ModelScope ofrece una API compatible con Anthropic. Aquí te muestro cómo modificar el código fuente de OpenCode para redirigir todas las llamadas a ModelScope.

## Visión General

| Archivo | Cambio |
|---------|--------|
| `src/utils/model/providers.ts` | Agregar `'modelscope'` al tipo `APIProvider` |
| `src/utils/model/configs.ts` | Agregar `modelscope: ''` a todos los configs |
| `src/services/api/client.ts` | Agregar rama para crear cliente con base URL de ModelScope |
| `src/utils/managedEnvConstants.ts` | Registrar `CLAUDE_CODE_USE_MODELSCOPE` como env var |
| `src/utils/auth.ts` | Actualizar `isUsing3PServices()` y `isAnthropicAuthEnabled()` |
| `src/utils/model/model.ts` | Default model ID para ModelScope |

## Paso 1: Definir el nuevo provider

**Archivo:** `src/utils/model/providers.ts`

```typescript
export type APIProvider = 'firstParty' | 'bedrock' | 'vertex' | 'foundry' | 'modelscope'

export function getAPIProvider(): APIProvider {
  return isEnvTruthy(process.env.CLAUDE_CODE_USE_BEDROCK)
    ? 'bedrock'
    : isEnvTruthy(process.env.CLAUDE_CODE_USE_VERTEX)
      ? 'vertex'
      : isEnvTruthy(process.env.CLAUDE_CODE_USE_FOUNDRY)
        ? 'foundry'
        : isEnvTruthy(process.env.CLAUDE_CODE_USE_MODELSCOPE)
          ? 'modelscope'
          : 'firstParty'
}
```

## Paso 2: Agregar campo `modelscope` a cada config

**Archivo:** `src/utils/model/configs.ts`

Agregar `modelscope: ''` a cada `CLAUDE_*_CONFIG` (11 configs: `CLAUDE_3_7_SONNET`, `CLAUDE_3_5_V2_SONNET`, `CLAUDE_3_5_HAIKU`, `CLAUDE_HAIKU_4_5`, `CLAUDE_SONNET_4`, `CLAUDE_SONNET_4_5`, `CLAUDE_OPUS_4`, `CLAUDE_OPUS_4_1`, `CLAUDE_OPUS_4_5`, `CLAUDE_OPUS_4_6`, `CLAUDE_SONNET_4_6`).

```typescript
export const CLAUDE_3_7_SONNET_CONFIG = {
  firstParty: 'claude-3-7-sonnet-20250219',
  bedrock: 'us.anthropic.claude-3-7-sonnet-20250219-v1:0',
  vertex: 'claude-3-7-sonnet@20250219',
  foundry: 'claude-3-7-sonnet',
  modelscope: '',
} as const satisfies ModelConfig
```

## Paso 3: Agregar el cliente ModelScope

**Archivo:** `src/services/api/client.ts`

Después del bloque de Vertex, antes del first-party default:

```typescript
if (isEnvTruthy(process.env.CLAUDE_CODE_USE_MODELSCOPE)) {
  const clientConfig: ConstructorParameters<typeof Anthropic>[0] = {
    apiKey: process.env.ANTHROPIC_API_KEY || apiKey,
    baseURL: process.env.ANTHROPIC_BASE_URL || 'https://api-inference.modelscope.ai',
    ...ARGS,
    ...(isDebugToStdErr() && { logger: createStderrLogger() }),
  }
  return new Anthropic(clientConfig)
}
```

## Paso 4: Registrar variable de entorno

**Archivo:** `src/utils/managedEnvConstants.ts`

En `PROVIDER_MANAGED_ENV_VARS` (después de `CLAUDE_CODE_USE_FOUNDRY`):

```typescript
'CLAUDE_CODE_USE_FOUNDRY',
'CLAUDE_CODE_USE_MODELSCOPE',
```

En `SAFE_ENV_VARS` (después de `CLAUDE_CODE_USE_FOUNDRY`):

```typescript
'CLAUDE_CODE_USE_FOUNDRY',
'CLAUDE_CODE_USE_MODELSCOPE',
'CLAUDE_CODE_USE_VERTEX',
```

## Paso 5: Actualizar verificación 3P

**Archivo:** `src/utils/auth.ts`

En `isAnthropicAuthEnabled()`:

```typescript
isEnvTruthy(process.env.CLAUDE_CODE_USE_BEDROCK) ||
isEnvTruthy(process.env.CLAUDE_CODE_USE_VERTEX) ||
isEnvTruthy(process.env.CLAUDE_CODE_USE_FOUNDRY) ||
isEnvTruthy(process.env.CLAUDE_CODE_USE_MODELSCOPE)
```

En `isUsing3PServices()`:

```typescript
export function isUsing3PServices(): boolean {
  return !!(
    isEnvTruthy(process.env.CLAUDE_CODE_USE_BEDROCK) ||
    isEnvTruthy(process.env.CLAUDE_CODE_USE_VERTEX) ||
    isEnvTruthy(process.env.CLAUDE_CODE_USE_FOUNDRY) ||
    isEnvTruthy(process.env.CLAUDE_CODE_USE_MODELSCOPE)
  )
}
```

## Paso 6: Default model para ModelScope (recomendado)

**Archivo:** `src/utils/model/model.ts`

ModelScope no sirve modelos Anthropic con los mismos IDs. Sin esto, `getDefaultOpusModel()` devuelve `''` (string vacío).

```typescript
export function getDefaultOpusModel(): ModelName {
  if (process.env.ANTHROPIC_DEFAULT_OPUS_MODEL) {
    return process.env.ANTHROPIC_DEFAULT_OPUS_MODEL
  }
  if (getAPIProvider() === 'modelscope') {
    return process.env.ANTHROPIC_MODEL || 'deepseek-ai/DeepSeek-V4-Flash'
  }
  // ...
}

export function getDefaultSonnetModel(): ModelName {
  if (process.env.ANTHROPIC_DEFAULT_SONNET_MODEL) {
    return process.env.ANTHROPIC_DEFAULT_SONNET_MODEL
  }
  if (getAPIProvider() === 'modelscope') {
    return process.env.ANTHROPIC_MODEL || 'deepseek-ai/DeepSeek-V4-Flash'
  }
  // ...
}

export function getDefaultHaikuModel(): ModelName {
  if (process.env.ANTHROPIC_DEFAULT_HAIKU_MODEL) {
    return process.env.ANTHROPIC_DEFAULT_HAIKU_MODEL
  }
  if (getAPIProvider() === 'modelscope') {
    return process.env.ANTHROPIC_MODEL || 'deepseek-ai/DeepSeek-V4-Flash'
  }
  // ...
}
```

## Uso con el binario global (sin recompilar)

Si no puedes recompilar el source (faltan módulos), usa el binario global de Claude con variables de entorno:

### PowerShell

```powershell
$env:ANTHROPIC_BASE_URL = "https://api-inference.modelscope.ai"
$env:ANTHROPIC_API_KEY = "ms-tu-token"
$env:ANTHROPIC_MODEL = "deepseek-ai/DeepSeek-V4-Flash"
claude
```

### Config persistente (`~/.claude/settings.json`)

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api-inference.modelscope.ai",
    "ANTHROPIC_API_KEY": "ms-tu-token",
    "ANTHROPIC_MODEL": "deepseek-ai/DeepSeek-V4-Flash"
  }
}
```

### Script lanzador

```powershell
.\claude-modelscope.ps1
```

## Modelos verificados

| Modelo | Estado |
|--------|--------|
| `deepseek-ai/DeepSeek-V4-Flash` | ✅ Funciona correctamente |
| `deepseek-ai/DeepSeek-V4-Pro` | ❌ Model ID inválido en streaming |

## Explicación del código Python vs TypeScript

Tu ejemplo Python:

```python
client = anthropic.Anthropic(
  base_url='https://api-inference.modelscope.ai',
  api_key='ms-...',
)
```

En TypeScript (OpenCode), el Anthropic SDK también acepta `baseURL` y `apiKey` en su constructor. La modificación en `client.ts` hace exactamente eso pero de forma configurable por environment variables, integrando ModelScope como un proveedor más al mismo nivel que Bedrock, Vertex y Foundry.

## Nota importante

ModelScope debe ser compatible con la API de Anthropic (mensajes, streaming, etc.). Si usas modelos no-Claude (como DeepSeek), la compatibilidad puede ser parcial. Algunas características (tools, system prompts, thinking) pueden no funcionar correctamente.
