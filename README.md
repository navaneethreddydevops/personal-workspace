# personal-workspace

Workspace scaffolding for GitHub Codespaces so every session starts with the same tooling. The devcontainer bundles Docker (via docker-in-docker), Kubernetes CLI utilities (k3d/k3s, kubectl, Helm), Terraform, and Python so you can go from blank repo to reproducible cloud-native workflows quickly.

## What's Included
- `.devcontainer/` definition that installs Docker plus an opinionated Kubernetes/DevOps toolbelt (k3d/k3s, kubectl, Helm, Terraform, Kustomize, k9s, kubectx/kubens, Stern, Flux, Argo CD CLI, Skaffold, yq, etc.) alongside Python 3.11, all running against an in-container Docker daemon.
- Custom Dockerfile that layers the official devcontainers base image with extra CLI helpers (curl, jq, make, etc.) and the `k3d` binary.
- k3s-in-Docker workflow via k3d, inspired by [Riaan Nolan's Kubernetes dev container guide](https://medium.com/@riaan.nolan/kubernetes-dev-container-88a777edc4b7).
- `.devcontainer/workspace-setup.sh` that bootstraps the in-container Docker daemon and owns the full Kubernetes automation workflow (validation, cluster create/delete, etc.).
- Curated VS Code extensions for Kubernetes/Helm/Docker/Terraform workflows, linting, DevOps automation, and Material-inspired themes/icons.

### Tool Versions
All CLI versions are pinned through build arguments in `.devcontainer/Dockerfile`, making upgrades a single-line change:

| Tool | Build ARG | Default |
| --- | --- | --- |
| k3d | `K3D_VERSION` | `v5.7.4` |
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
   - The startup sequence runs `bash .devcontainer/workspace-setup.sh post-create`, which launches the Docker daemon inside the devcontainer, validates tooling, and automatically provisions the default `workspace` k3s cluster via k3d (unset by setting `K3D_AUTO_CREATE=false`).
   - Recreate, validate, or delete the cluster anytime with `bash .devcontainer/workspace-setup.sh <command>` (see below for examples).
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
   - The post-create hook automatically provisions the `workspace` k3s cluster, so expect to see k3d status output (cluster create, kubeconfig export).
3. **Clean up when finished**  
   ```bash
   docker rm -f $(docker ps -aq --filter label=devcontainer.local_folder=$PWD) || true
   ```
   All k3d nodes live inside the devcontainer’s Docker daemon, so removing the devcontainer automatically deletes them. Remove or archive `/tmp/devcontainer-test.log` if you no longer need the build log.

## Kubernetes Automation
`.devcontainer/workspace-setup.sh` is the single entrypoint for Docker startup plus Kubernetes automation. By default it validates the toolchain and creates a local k3s cluster via k3d (`${K3D_CLUSTER_NAME:-workspace}`) every time the devcontainer is (re)built. Tweak the behavior via environment variables:

- `K3D_AUTO_CREATE` (default `true`) — set to `false` in `devcontainer.json` to skip automatic cluster creation.
- `K3D_WAIT_SECONDS` (default `60`) — how long to wait for k3d to become ready.
- `K3D_CLUSTER_NAME` — cluster name passed through to k3d.

You can also run the script manually when you need to interact with the cluster lifecycle:

```bash
# Validate that all CLI tools are installed (used automatically post-create)
bash .devcontainer/workspace-setup.sh validate

# Force-create or refresh the cluster with a different wait time
bash .devcontainer/workspace-setup.sh post-create --auto-create --wait 120

# Delete the cluster
bash .devcontainer/workspace-setup.sh delete
```

`K3D_CLUSTER_NAME` controls the cluster name (defaults to `workspace`). Override it before running the script if you need multiple clusters.

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
