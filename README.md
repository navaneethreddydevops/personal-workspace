# personal-workspace

Workspace scaffolding for GitHub Codespaces so every session starts with the same tooling. The devcontainer bundles Docker (via docker-in-docker), Kubernetes CLI utilities (kind, kubectl, Helm), Terraform, and Python so you can go from blank repo to reproducible cloud-native workflows quickly.

## What's Included
- `.devcontainer/` definition that installs Docker, kubectl, Helm, Terraform, and Python 3.11.
- Custom Dockerfile that layers the official devcontainers base image with extra CLI helpers (curl, jq, make, etc.) and the `kind` binary.
- `scripts/setup-kubernetes.sh` for creating or deleting a local kind cluster directly inside the Codespace.
- Curated VS Code extensions for Kubernetes/Helm/Docker/Terraform workflows, linting, DevOps automation, and Material-inspired themes/icons.

## How to Start
1. **Open the repo in Codespaces**
   - In GitHub, click **Code → Codespaces → Create codespace on master** (or run `gh codespace create --repo <owner>/<repo>` if you prefer the CLI).
   - Codespaces automatically builds the devcontainer using `.devcontainer/`.
2. **(Optional) Use VS Code locally**
   - Install the **Dev Containers** extension.
   - Run `Dev Containers: Clone Repository in Container Volume...` and choose this repo, or `Dev Containers: Rebuild and Reopen in Container` if already cloned.
3. **Bootstrap Kubernetes**
   - After the container finishes provisioning (either via Codespaces or local devcontainer), run `./scripts/setup-kubernetes.sh` to create the default `workspace` kind cluster.
   - To remove the cluster, run `./scripts/setup-kubernetes.sh --delete`.
4. **Start building**
   - All required CLIs (`kubectl`, `helm`, `docker`, `terraform`, `python3`, etc.) are on PATH and ready for immediate use.

## Kubernetes Helper Script
The helper supports the following flags:

```bash
# Validate that all CLI tools are installed (used automatically post-create)
./scripts/setup-kubernetes.sh --validate-only

# Create/update the cluster (default behavior)
./scripts/setup-kubernetes.sh --wait 120

# Delete the cluster
./scripts/setup-kubernetes.sh --delete
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
