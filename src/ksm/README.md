
# Keeper Secrets Manager (ksm)

Installs the [Keeper Secrets Manager CLI](https://docs.keeper.io/secrets-manager/secrets-manager/secrets-manager-command-line-interface) (`ksm`) and provides mechanisms to:
- Forward `KSM_CONFIG` from the local host environment into the container
- Automatically initialize environment variables from Keeper Secrets on container startup

## How KSM_CONFIG is forwarded

`KSM_CONFIG` holds the base64-encoded configuration used to authenticate with Keeper Secrets Manager. The `config` option can receive the value from your local `KSM_CONFIG` environment variable (using `${localEnv:KSM_CONFIG}`), which is resolved by the devcontainer CLI before being passed to the container. This allows the KSM CLI to be ready to use without any manual setup inside the container.

> **Security note:** `KSM_CONFIG` contains sensitive credentials. Ensure your container is properly isolated and that the value is not logged or exposed via container introspection (e.g., `docker inspect`). Avoid committing `KSM_CONFIG` to source control or sharing it in logs.

## Example Usage

### Minimal Setup (auto-forward local KSM_CONFIG)

```json
"features": {
    "../../devcontainer-features/src/ksm": {}
}
```

### With Keeper Secrets Auto-Initialization

```json
"features": {
    "../../devcontainer-features/src/ksm": {
        "config": "${localEnv:KSM_CONFIG}",
        "secrets": "{\"DB_PASSWORD\": \"keeper/K9mZx8yW7vU6tS5rQ4pO3n/password\", \"API_KEY\": \"keeper/XYZ123ABC/api_key\", \"JASYPT_ENCRYPTOR_PASSWORD\": \"keeper/K9mZx8yW7vU6tS5rQ4pO3n/password\"}"
    }
}
```
When the container starts, these environment variables will be automatically fetched from Keeper and made available in the shell.

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version of KSM CLI to install. Use 'latest' for the most recent version. | string | latest |
| config | KSM_CONFIG value to forward into the container. Defaults to the local KSM_CONFIG environment variable. | string | `${localEnv:KSM_CONFIG}` |
| secrets | JSON object mapping environment variable names to Keeper secret references. Format: `{"ENV_VAR_NAME": "keeper/uid/field"}`. Example: `{"JASYPT_ENCRYPTOR_PASSWORD": "keeper/K9mZx8yW7vU6tS5rQ4pO3n/password"}` | string | (none) |

### Keeper Secrets Format

The `secrets` option accepts a JSON string where:
- **Key** = the environment variable name (e.g., `DB_PASSWORD`, `API_KEY`, `JASYPT_ENCRYPTOR_PASSWORD`)
- **Value** = a secret reference in the format: `keeper/<uid>/<field>`
  - `uid`: The record UID in Keeper
  - `field`: The field name within that record (e.g., `password`, `api_key`, `token`)

**Example:**
```json
"secrets": "{DB_PASSWORD: keeper/K9mZx8yW7vU6tS5rQ4pO3n/password, API_KEY: keeper/XYZ123ABC/api_key, JASYPT_ENCRYPTOR_PASSWORD: keeper/K9mZx8yW7vU6tS5rQ4pO3n/password}"
```

Or more readably:
```json
{
  "DB_PASSWORD": "keeper/K9mZx8yW7vU6tS5rQ4pO3n/password",
  "API_KEY": "keeper/XYZ123ABC/api_key",
  "JASYPT_ENCRYPTOR_PASSWORD": "keeper/K9mZx8yW7vU6tS5rQ4pO3n/password"
}
```

### How Keeper Secrets are Initialized

1. The feature creates `/usr/local/bin/ksm-init-secrets.py` - a Python script that generate commands to fetches secrets
2. A profile script at `/etc/profile.d/ksm-secrets.sh` automatically eval the python script output when a shell starts
3. Each secret is fetched using: `ksm secret get --uid <uid> --field <field>`
4. Environment variables are exported and available in the shell environment

**Requirements:**
- `KSM_CONFIG` must be set for secret fetching to work
- The KSM CLI must be able to authenticate with Keeper using the provided `KSM_CONFIG`
- The user context must have access to the specified Keeper records

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/cdsolinfo/devcontainer-features/blob/main/src/ksm/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
