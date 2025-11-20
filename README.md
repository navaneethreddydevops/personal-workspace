# personal-workspace

Workspace scaffolding for GitHub Codespaces so every session starts with the same tooling. The devcontainer bundles Docker-in-Docker plus Kubernetes/DevOps utilities (k3d/k3s, kubectl, Helm), Terraform, and Python so you can go from blank repo to reproducible cloud-native workflows quickly.

## What's Included
- `.devcontainer/` definition that builds a Docker-in-Docker environment with an opinionated Kubernetes/DevOps toolbelt (k3d/k3s, kubectl, Helm, Terraform, Kustomize, k9s, kubectx/kubens, Stern, Flux, Argo CD CLI, Skaffold, yq, etc.) alongside Python 3.11.
- Custom Dockerfile that layers the official devcontainers base image with extra CLI helpers (curl, jq, make, etc.) and installs `k3d` directly in the image.
- Docker daemon is started by the container entrypoint—no extra workspace bootstrap script required.
- k3s-in-Docker workflow via k3d, inspired by [Riaan Nolan's Kubernetes dev container guide](https://medium.com/@riaan.nolan/kubernetes-dev-container-88a777edc4b7).
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
3. **Bootstrap Kubernetes (optional)**
   - The Docker daemon starts automatically (dind) when the container runs. Create a k3s cluster on demand:
   ```bash
   k3d cluster create ${K3D_CLUSTER_NAME:-workspace} --wait --kubeconfig-update-default --kubeconfig-switch-context
   ```
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
   docker info
   k3d cluster create workspace --wait --kubeconfig-update-default --kubeconfig-switch-context
   ```
   - The run succeeds when `docker info` returns without errors. The `k3d cluster create` call is optional if you only need the toolchain.
3. **Clean up when finished**  
   ```bash
   docker rm -f $(docker ps -aq --filter label=devcontainer.local_folder=$PWD) || true
   ```
   All k3d nodes live inside the devcontainer’s Docker daemon, so removing the devcontainer automatically deletes them. Remove or archive `/tmp/devcontainer-test.log` if you no longer need the build log.

## Kubernetes Automation
`K3D_CLUSTER_NAME` controls the default cluster name (defaults to `workspace`). Manage the lifecycle directly with k3d:

```bash
# Create a cluster (wait for readiness, update kubeconfig)
k3d cluster create ${K3D_CLUSTER_NAME:-workspace} --wait --kubeconfig-update-default --kubeconfig-switch-context

# Export kubeconfig manually if you skipped --kubeconfig-update-default
k3d kubeconfig get ${K3D_CLUSTER_NAME:-workspace} > ~/.kube/config

# Delete the cluster when you are done
k3d cluster delete ${K3D_CLUSTER_NAME:-workspace}
```

## Customizing the Devcontainer
- Adjust tool versions via build arguments in `.devcontainer/Dockerfile` or tweak the env/ports in `.devcontainer/devcontainer.json`.
- Extend the base image or install extra apt packages through `.devcontainer/Dockerfile`.
- Update VS Code settings/extensions via the `customizations` block.

### Included VS Code Extensions
- Containers & DevOps: `ms-azuretools.vscode-docker`, `github.vscode-github-actions`, `ms-azure-devops.azure-pipelines`, `eamodio.gitlens`.
- Kubernetes & IaC: `ms-kubernetes-tools.vscode-kubernetes-tools`, `hashicorp.terraform`, `ms-vscode.makefile-tools`.
- Python & linting: `ms-python.python`, `ms-python.vscode-pylance`, `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`, `redhat.vscode-yaml`, `streetsidesoftware.code-spell-checker`, `editorconfig.editorconfig`.
- Themes & icons: `PKief.material-icon-theme`.
- AI assistance: `github.copilot`, `github.copilot-chat`.
