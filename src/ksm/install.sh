#!/bin/sh
set -e

echo "Activating feature 'ksm'"

VERSION=${VERSION:-latest}
CONFIG=${CONFIG:-}
SECRETS=${SECRETS:-}

echo "KSM CLI version to install: $VERSION"
if [ -n "$CONFIG" ]; then
    echo "CONFIG found (length: ${#CONFIG})"
fi
if [ -n "$SECRETS" ]; then
    echo "SECRETS found: $SECRETS"
else
    echo "DEBUG: SECRETS is empty or not set"
fi

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

# Install pip if not already available
if ! command -v pip3 > /dev/null 2>&1; then
    echo "Installing pip..."
    apt-get update -y
    apt-get install -y python3-pip
fi

# Install the Keeper Secrets Manager CLI
if [ "$VERSION" = "latest" ]; then
    echo "Installing latest version of keeper-secrets-manager-cli..."
    pip3 install --break-system-packages keeper-secrets-manager-cli \
        || pip3 install keeper-secrets-manager-cli
else
    echo "Installing keeper-secrets-manager-cli==${VERSION}..."
    pip3 install --break-system-packages "keeper-secrets-manager-cli==${VERSION}" \
        || pip3 install "keeper-secrets-manager-cli==${VERSION}"
fi

pip3 install --break-system-packages json-repair

echo "KSM CLI installed successfully."

# Set up KSM_CONFIG in the container if provided
if [ -n "$CONFIG" ]; then
    KSM_PROFILE_DIR="/etc/profile.d"
    KSM_PROFILE_FILE="${KSM_PROFILE_DIR}/ksm-config.sh"
    
    mkdir -p "${KSM_PROFILE_DIR}"
    
    cat > "${KSM_PROFILE_FILE}" << EOF
# Export KSM_CONFIG in the container (forwarded from host CONFIG)
export KSM_CONFIG="$CONFIG"
EOF
    
    chmod 644 "${KSM_PROFILE_FILE}"
    echo "CONFIG forwarded - will be available as KSM_CONFIG in shell."
else
    echo "Note: CONFIG was not provided to the feature."
fi

# Set up Keeper Secrets initialization if provided
if [ -n "$SECRETS" ]; then
    echo "Setting up Keeper Secrets initialization..."
    KSM_INIT_DIR="/usr/local/bin"
    KSM_INIT_SCRIPT="${KSM_INIT_DIR}/ksm-init-secrets.py"
    
    cat > "${KSM_INIT_SCRIPT}" << PYSCRIPT
#!/usr/bin/env python3
from json_repair import repair_json
import json
import subprocess
import os
import sys
import shlex

# Secrets configuration is baked in at container build time
keeper_secrets_json = """$SECRETS"""

try:
    secrets = json.loads(repair_json(keeper_secrets_json))
except json.JSONDecodeError as e:
    print(f"echo 'Error: Invalid JSON in SECRETS: {e}' >&2")
    sys.exit(1)

for env_var_name, secret_ref in secrets.items():
    try:
        if not isinstance(secret_ref, str):
            print(f"echo 'Error: Secret reference for {env_var_name} must be a string, got {type(secret_ref).__name__}' >&2")
            continue
        
        # Parse "keeper/uid/field" format
        if not secret_ref.startswith('keeper/'):
            print(f"echo 'Error: Secret reference for {env_var_name} must start with keeper/, got: {secret_ref}' >&2")
            continue
        
        parts = secret_ref.split('/')
        if len(parts) != 3:
            print(f"echo 'Error: Invalid secret reference format for {env_var_name}: {secret_ref}. Expected keeper/uid/field' >&2")
            continue
        
        uid = parts[1]
        field = parts[2]
        
        if not uid or not field:
            print(f"echo 'Error: Missing uid or field in reference for {env_var_name}' >&2")
            continue
        
        result = subprocess.run(
            ['ksm', 'secret', 'get', '--uid', uid, '--field', field],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            secret_value = shlex.quote(result.stdout.strip())
            print(f"export {env_var_name}={secret_value}")
            print(f"echo 'Initialized {env_var_name} from Keeper Secrets' >&2")
        else:
            print(f"echo 'Error: Failed to fetch {env_var_name}: {result.stderr}' >&2")
    except subprocess.TimeoutExpired:
        print(f"echo 'Error: Timeout fetching {env_var_name}' >&2")
    except Exception as e:
        print(f"echo 'Error: {e}' >&2")
PYSCRIPT
    
    chmod +x "${KSM_INIT_SCRIPT}"

    # Add sourcing of the wrapper to the profile
    KSM_PROFILE_DIR="/etc/profile.d"
    KSM_PROFILE_FILE="${KSM_PROFILE_DIR}/ksm-secrets.sh"
    
    mkdir -p "${KSM_PROFILE_DIR}"
    
    cat > "${KSM_PROFILE_FILE}" << 'EOF'
# Initialize Keeper Secrets if SECRETS environment variable is set
eval "$(/usr/local/bin/ksm-init-secrets.py)"
EOF
    
    chmod 644 "${KSM_PROFILE_FILE}"
    echo "Keeper Secrets initialization script has been set up."
else
    echo "Note: No Keeper Secrets were specified for initialization."
fi
