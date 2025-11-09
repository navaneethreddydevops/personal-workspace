# personal-workspace

Workspace scaffolding for GitHub Codespaces so every session starts with the same tooling. The devcontainer bundles Docker (via docker-in-docker), Kubernetes CLI utilities (kind, kubectl, Helm), Terraform, and Python so you can go from blank repo to reproducible cloud-native workflows quickly.

## What's Included
- `.devcontainer/` definition that installs Docker plus an opinionated Kubernetes/DevOps toolbelt (kind, kubectl, Helm, Terraform, Kustomize, k9s, kubectx/kubens, Stern, Flux, Argo CD CLI, Skaffold, yq, etc.) alongside Python 3.11, all running against an in-container Docker daemon.
- Custom Dockerfile that layers the official devcontainers base image with extra CLI helpers (curl, jq, make, etc.) and the `kind` binary.
- `.devcontainer/start-docker.sh` + `.devcontainer/post-create.sh` that bootstrap the in-container Docker daemon and own the full Kubernetes automation workflow (validation, cluster create/delete, etc.).
- Curated VS Code extensions for Kubernetes/Helm/Docker/Terraform workflows, linting, DevOps automation, and Material-inspired themes/icons.

### Tool Versions
All CLI versions are pinned through build arguments in `.devcontainer/Dockerfile`, making upgrades a single-line change:

| Tool | Build ARG | Default |
| --- | --- | --- |
| kind | `KIND_VERSION` | `v0.23.0` |
| kubectl | `KUBECTL_VERSION` | `v1.28.3` |
| Helm | `HELM_VERSION` | `v3.13.2` |
| Terraform | `TERRAFORM_VERSION` | `1.6.3` |
| Kustomize | `KUSTOMIZE_VERSION` | `v5.3.0` |
| k9s | `K9S_VERSION` | `v0.32.4` |
| kubectx/kubens | `KUBECTX_VERSION` / `KUBENS_VERSION` | `v0.9.5` |
| Stern | `STERN_VERSION` | `v1.29.0` |
| Skaffold | `SKAFFOLD_VERSION` | `v2.10.0` |
| Flux CLI | `FLUX_VERSION` | `v2.3.0` |
| Argo CD CLI | `ARGOCD_VERSION` | `v2.9.5` |
| yq | `YQ_VERSION` | `v4.44.1` |

## How to Start
1. **Open the repo in Codespaces**
   - In GitHub, click **Code → Codespaces → Create codespace on master** (or run `gh codespace create --repo <owner>/<repo>` if you prefer the CLI).
   - Codespaces automatically builds the devcontainer using `.devcontainer/`.
2. **(Optional) Use VS Code locally**
   - Install the **Dev Containers** extension.
   - Run `Dev Containers: Clone Repository in Container Volume...` and choose this repo, or `Dev Containers: Rebuild and Reopen in Container` if already cloned.
3. **Bootstrap Kubernetes**
   - The startup sequence (`start-docker.sh` + `post-create.sh`) launches a Docker daemon inside the devcontainer, validates tooling, and automatically provisions the default `workspace` kind cluster (unset by setting `KIND_AUTO_CREATE=false`).
   - If you need to recreate or delete the cluster later, run `bash .devcontainer/post-create.sh` with the appropriate flags (see below).
4. **Start building**
   - All required CLIs (`kubectl`, `helm`, `docker`, `terraform`, `python3`, etc.) are on PATH and ready for immediate use.

## Testing the Devcontainer Locally
Use the VS Code Dev Containers CLI to build and smoke-test the environment without opening a Codespace:

1. **Install the CLI (once)**  
   ```bash
   npm install -g @devcontainers/cli
   ```
2. **Build and run the container**  
   ```bash
   DEVCONTAINER_DISABLE_LOG_TRUNCATE=true devcontainer up --workspace-folder . --log-level info > /tmp/devcontainer-test.log 2>&1
   tail -n 40 /tmp/devcontainer-test.log
   ```
   - The run succeeds when the log shows `Container started` followed by `Cluster created. KUBECONFIG=/home/vscode/.kube/config`.
   - The post-create hook automatically provisions the `workspace` kind cluster, so expect to see the usual kind status output.
3. **Clean up when finished**  
   ```bash
   docker rm -f $(docker ps -aq --filter label=devcontainer.local_folder=$PWD) || true
   ```
   All kind nodes live inside the devcontainer’s Docker daemon, so removing the devcontainer automatically deletes them. Remove or archive `/tmp/devcontainer-test.log` if you no longer need the build log.

## Kubernetes Automation
`.devcontainer/start-docker.sh` ensures the Docker daemon is running inside the container, and `.devcontainer/post-create.sh` layers the Kubernetes/bootstrap logic on top. By default the combo validates the toolchain and creates a local kind cluster (`${KIND_CLUSTER_NAME:-workspace}`) every time the devcontainer is (re)built. Tweak the behavior via environment variables:

- `KIND_AUTO_CREATE` (default `true`) — set to `false` in `devcontainer.json` to skip automatic cluster creation.
- `KIND_WAIT_SECONDS` (default `60`) — how long to wait for kind to become ready.
- `KIND_CLUSTER_NAME` — cluster name passed through to `kind`.

You can also run the script manually when you need to interact with the cluster lifecycle:

```bash
# Validate that all CLI tools are installed (used automatically post-create)
bash .devcontainer/post-create.sh --validate-only

# Force-create or refresh the cluster with a different wait time
bash .devcontainer/post-create.sh --auto-create --wait 120

# Delete the cluster
bash .devcontainer/post-create.sh --delete
```

`KIND_CLUSTER_NAME` controls the cluster name (defaults to `workspace`). Override it before running the script if you need multiple clusters.

## Customizing the Devcontainer
- Adjust tool versions or add new ones in `.devcontainer/devcontainer.json`.
- Extend the base image or install extra apt packages through `.devcontainer/Dockerfile`.
- Update VS Code settings/extensions via the `customizations` block.

### Included VS Code Extensions
- Kubernetes & Helm: `ms-kubernetes-tools.vscode-kubernetes-tools`, `ms-kubernetes-tools.vscode-helm`, `mindaro.mindaro`.
- Docker & DevOps: `ms-azuretools.vscode-docker`, `github.vscode-github-actions`, `ms-azure-devops.azure-pipelines`, `eamodio.gitlens`.
- IaC & cloud: `hashicorp.terraform`, `ms-vscode.makefile-tools`.
- Linting & formatting: `dbaeumer.vscode-eslint`, `ms-python.vscode-pylance`, `esbenp.prettier-vscode`, `redhat.vscode-yaml`, `streetsidesoftware.code-spell-checker`, `editorconfig.editorconfig`.
- Themes & icons: `Equinusocio.vsc-material-theme`, `PKief.material-icon-theme`.

Rebuild the container (`Codespaces: Rebuild Container`) after making changes so the new environment takes effect.
