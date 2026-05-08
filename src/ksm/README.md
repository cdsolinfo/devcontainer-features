
# Keeper Secrets Manager (KSM) (ksm)

Installs the Keeper Secrets Manager CLI (ksm) and forwards KSM_CONFIG from the local host environment into the container.

## Example Usage

```json
"features": {
    "ghcr.io/cdsolinfo/devcontainer-features/ksm:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version of KSM CLI to install. Use 'latest' for the most recent version. | string | latest |
| config | KSM_CONFIG value to forward into the container. Defaults to the local KSM_CONFIG environment variable. | string | ${localEnv:KSM_CONFIG} |
| secrets | JSON object mapping environment variable names to Keeper secret references. Format: {ENV_VAR_NAME: keeper/uid/field}. Example: {JASYPT_ENCRYPTOR_PASSWORD: keeper/K9mZx8yW7vU6tS5rQ4pO3n/password} | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/cdsolinfo/devcontainer-features/blob/main/src/ksm/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
