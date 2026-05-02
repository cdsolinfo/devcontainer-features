# Dev Container Features: cdsolinfo/devcontainers

This repository hosts custom [dev container Features](https://containers.dev/implementors/features/), published to GitHub Container Registry (GHCR) following the [dev container Feature distribution specification](https://containers.dev/implementors/features-distribution/).

## Features

### `ksm` — Keeper Secrets Manager

Installs the [Keeper Secrets Manager CLI](https://docs.keeper.io/secrets-manager/secrets-manager/secrets-manager-command-line-interface) (`ksm`) and forwards `KSM_CONFIG` from the local host environment into the container.

`KSM_CONFIG` holds the base64-encoded configuration used to authenticate with Keeper Secrets Manager. This feature uses the devcontainer `containerEnv` mechanism (`${localEnv:KSM_CONFIG}`) to transparently pass the variable from your local machine into the container, so the KSM CLI is ready to use without any manual setup inside the container.

> **Security note:** `KSM_CONFIG` contains sensitive credentials. Ensure your container is properly isolated and that the value is not logged or exposed via container introspection (e.g., `docker inspect`). Avoid committing `KSM_CONFIG` to source control or sharing it in logs.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/cdsolinfo/devcontainers/ksm:1": {}
    }
}
```

#### Options

| Option Id | Description | Type | Default |
|-----------|-------------|------|---------|
| `version` | Select the version of KSM CLI to install. Use `latest` for the most recent version. | string | `latest` |

## Repo and Feature Structure

This repository has a `src` folder.  Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`.

```
├── src
│   ├── ksm
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
...
```

An [implementing tool](https://containers.dev/supporting#tools) will composite [the documented dev container properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) from the feature's `devcontainer-feature.json` file, and execute the `install.sh` entrypoint script in the container during build time.

## Distributing Features

### Versioning

Features are individually versioned by the `version` attribute in a Feature's `devcontainer-feature.json`.  Features are versioned according to the semver specification. More details can be found in [the dev container Feature specification](https://containers.dev/implementors/features/#versioning).

### Publishing

> NOTE: The Distribution spec can be [found here](https://containers.dev/implementors/features-distribution/).  
>
> While any registry [implementing the OCI Distribution spec](https://github.com/opencontainers/distribution-spec) can be used, this template will leverage GHCR (GitHub Container Registry) as the backing registry.

Features are meant to be easily sharable units of dev container configuration and installation code.  

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR. 

*Allow GitHub Actions to create and approve pull requests* should be enabled in the repository's `Settings > Actions > General > Workflow permissions` for auto generation of `src/<feature>/README.md` per Feature (which merges any existing `src/<feature>/NOTES.md`).

By default, each Feature will be prefixed with the `<owner>/<repo>` namespace.  For example, the Feature in this repository can be referenced in a `devcontainer.json` with:

```
ghcr.io/cdsolinfo/devcontainers/ksm:1
```

The provided GitHub Action will also publish a third "metadata" package with just the namespace, eg: `ghcr.io/cdsolinfo/devcontainers`.  This contains information useful for tools aiding in Feature discovery.

'`cdsolinfo/devcontainers`' is known as the feature collection namespace.

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`.  To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to 'public`.  The URL may look something like:

```
https://github.com/users/cdsolinfo/packages/container/devcontainers%2Fksm/settings
```

<img width="669" alt="image" src="https://user-images.githubusercontent.com/23246594/185244705-232cf86a-bd05-43cb-9c25-07b45b3f4b04.png">

### Adding Features to the Index

If you'd like your Features to appear in our [public index](https://containers.dev/features) so that other community members can find them, you can do the following:

* Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
     * This is the GitHub repo backing the [containers.dev](https://containers.dev/) spec site
* Open a PR to modify the [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml) file

This index is from where [supporting tools](https://containers.dev/supporting) like [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and [GitHub Codespaces](https://github.com/features/codespaces) surface Features for their dev container creation UI.

#### Using private Features in Codespaces

For any Features hosted in GHCR that are kept private, the `GITHUB_TOKEN` access token in your environment will need to have `package:read` and `contents:read` for the associated repository.

Many implementing tools use a broadly scoped access token and will work automatically.  GitHub Codespaces uses repo-scoped tokens, and therefore you'll need to add the permissions in `devcontainer.json`

An example `devcontainer.json` can be found below.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
     "ghcr.io/my-org/private-features/hello:1": {
            "greeting": "Hello"
        }
    },
    "customizations": {
        "codespaces": {
            "repositories": {
                "my-org/private-features": {
                    "permissions": {
                        "packages": "read",
                        "contents": "read"
                    }
                }
            }
        }
    }
}
```
