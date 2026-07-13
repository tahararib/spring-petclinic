#!/bin/bash
# ============================================================
# install-wsl2.sh — Formation Ingénierie DevOps Open Source
# CapabilityForge / Tahar ARIB
#
# Exécuter dans WSL2 Ubuntu 24.04 :
#   bash install-wsl2.sh
# Exécuter une seule étape :
#   bash install-wsl2.sh step_03
#
# Toutes les commandes d'installation ont été vérifiées
# sur la documentation officielle de chaque outil.
# ============================================================

set -euo pipefail

STEP=${1:-all}

# ────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}$*${NC}"; }
ok()   { echo -e "  ${GREEN}✓ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ $*${NC}"; }
err()  { echo -e "  ${RED}✗ $*${NC}"; exit 1; }

is_installed() { command -v "$1" &>/dev/null; }

# ────────────────────────────────────────────────
step_01_update_system() {
    log "[01/12] Mise à jour du système Ubuntu 24.04..."
    sudo apt-get update -q
    sudo apt-get upgrade -y -q
    ok "Système à jour"
}

# ────────────────────────────────────────────────
step_02_install_base_tools() {
    log "[02/12] Outils de base (curl, wget, git, jq, make, unzip, ca-certificates)..."
    sudo apt-get install -y -q \
        curl wget git jq make unzip \
        ca-certificates gnupg lsb-release \
        apt-transport-https software-properties-common
    ok "Outils de base installés"
    git --version
    jq --version
}

# ────────────────────────────────────────────────
# Source : https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
step_03_install_kubectl() {
    log "[03/12] kubectl..."

    if is_installed kubectl; then
        ok "kubectl déjà installé ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
        return
    fi

    # Méthode officielle : téléchargement binaire depuis dl.k8s.io
    # NE PAS utiliser apt - kubectl n'est pas dans les dépôts Ubuntu standard
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

    # Vérification checksum (recommandé par la doc officielle)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl kubectl.sha256

    ok "kubectl installé ($(kubectl version --client --short 2>/dev/null || echo ${KUBECTL_VERSION}))"
}

# ────────────────────────────────────────────────
# Source : https://helm.sh/docs/intro/install/
step_04_install_helm() {
    log "[04/12] Helm..."

    if is_installed helm; then
        ok "Helm déjà installé ($(helm version --short))"
        return
    fi

    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    ok "Helm installé ($(helm version --short))"
}

# ────────────────────────────────────────────────
# Source : https://k3d.io/v5.7.4/#installation
step_05_install_k3d() {
    log "[05/12] k3d..."

    if is_installed k3d; then
        ok "k3d déjà installé ($(k3d version | head -1))"
        return
    fi

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    ok "k3d installé ($(k3d version | head -1))"
}

# ────────────────────────────────────────────────
# Source : https://mise.jdx.dev/getting-started.html
step_06_install_mise() {
    log "[06/12] mise (gestionnaire de versions d'outils)..."

    if is_installed mise; then
        ok "mise déjà installé ($(mise --version))"
        return
    fi

    curl https://mise.run | sh

    # Activation dans .bashrc si pas déjà présent
    if ! grep -q 'mise activate' ~/.bashrc; then
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
    fi
    eval "$(~/.local/bin/mise activate bash)" 2>/dev/null || true

    ok "mise installé"
    warn "Exécuter : source ~/.bashrc  pour activer mise dans la session courante"
}

# ────────────────────────────────────────────────
# Source : https://opentofu.org/docs/intro/install/deb/
step_07_install_opentofu() {
    log "[07/12] OpenTofu..."

    if is_installed tofu; then
        ok "OpenTofu déjà installé ($(tofu --version | head -1))"
        return
    fi

    # Installation via le repo APT officiel OpenTofu
    curl -fsSL https://get.opentofu.org/opentofu.gpg \
        | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null

    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
        | sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null

    echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] \
https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] \
https://packages.opentofu.org/opentofu/tofu/any/ any main" \
    | sudo tee /etc/apt/sources.list.d/opentofu.list

    sudo apt-get update -q
    sudo apt-get install -y -q tofu

    ok "OpenTofu installé ($(tofu --version | head -1))"
}

# ────────────────────────────────────────────────
step_08_install_ansible() {
    log "[08/12] Ansible..."

    if is_installed ansible; then
        ok "Ansible déjà installé ($(ansible --version | head -1))"
        return
    fi

    # Ansible via PPA Ubuntu officiel (recommandé pour Ubuntu 24.04)
    sudo apt-get install -y -q software-properties-common
    sudo add-apt-repository -y ppa:ansible/ansible
    sudo apt-get update -q
    sudo apt-get install -y -q ansible

    ok "Ansible installé ($(ansible --version | head -1))"
}

# ────────────────────────────────────────────────
# Source : https://argo-cd.readthedocs.io/en/stable/cli_installation/
step_09_install_argocd_cli() {
    log "[09/12] ArgoCD CLI..."

    if is_installed argocd; then
        ok "ArgoCD CLI déjà installé ($(argocd version --client 2>/dev/null | head -1))"
        return
    fi

    ARGOCD_VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
    curl -sSL -o argocd-linux-amd64 \
        "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64"
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    ok "ArgoCD CLI installé (v${ARGOCD_VERSION})"
}

# ────────────────────────────────────────────────
# Trivy  : https://aquasecurity.github.io/trivy/latest/getting-started/installation/
# cosign : https://docs.sigstore.dev/cosign/system_config/installation/
# stern  : https://github.com/stern/stern/releases
step_10_install_security_tools() {
    log "[10/12] Trivy + cosign + stern..."

    # ── Trivy ──────────────────────────────────────
    if is_installed trivy; then
        ok "Trivy déjà installé ($(trivy --version | head -1))"
    else
        sudo apt-get install -y -q wget apt-transport-https gnupg
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
            | gpg --dearmor \
            | sudo tee /etc/apt/keyrings/trivy.gpg > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
            | sudo tee /etc/apt/sources.list.d/trivy.list
        sudo apt-get update -q
        sudo apt-get install -y -q trivy
        ok "Trivy installé ($(trivy --version | head -1))"
    fi

    # ── cosign ─────────────────────────────────────
    if is_installed cosign; then
        ok "cosign déjà installé ($(cosign version 2>&1 | grep GitVersion | awk '{print $2}'))"
    else
        COSIGN_VERSION=$(curl -s "https://api.github.com/repos/sigstore/cosign/releases/latest" \
            | jq -r '.tag_name')
        curl -sSL -o cosign \
            "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
        sudo chmod +x cosign
        sudo mv cosign /usr/local/bin/cosign
        ok "cosign installé (${COSIGN_VERSION})"
    fi

    # ── stern ──────────────────────────────────────
    if is_installed stern; then
        ok "stern déjà installé ($(stern --version))"
    else
        STERN_VERSION=$(curl -s "https://api.github.com/repos/stern/stern/releases/latest" \
            | jq -r '.tag_name')
        curl -sSL -o stern.tar.gz \
            "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_linux_amd64.tar.gz"
        tar xzf stern.tar.gz stern
        sudo mv stern /usr/local/bin/stern
        rm stern.tar.gz
        ok "stern installé (${STERN_VERSION})"
    fi
}

# ────────────────────────────────────────────────
# k9s  : https://github.com/derailed/k9s/releases
# yq   : https://github.com/mikefarah/yq/releases
step_11_install_k9s_and_tools() {
    log "[11/12] k9s + yq..."

    # ── k9s ────────────────────────────────────────
    if is_installed k9s; then
        ok "k9s déjà installé ($(k9s version --short 2>/dev/null | head -1))"
    else
        K9S_VERSION=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" \
            | jq -r '.tag_name')
        curl -sSL -o k9s.tar.gz \
            "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
        tar xzf k9s.tar.gz k9s
        sudo mv k9s /usr/local/bin/k9s
        rm k9s.tar.gz
        ok "k9s installé (${K9S_VERSION})"
    fi

    # ── yq ─────────────────────────────────────────
    if is_installed yq; then
        ok "yq déjà installé ($(yq --version))"
    else
        YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" \
            | jq -r '.tag_name')
        curl -sSL -o yq \
            "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
        sudo chmod +x yq
        sudo mv yq /usr/local/bin/yq
        ok "yq installé (${YQ_VERSION})"
    fi
}

# ────────────────────────────────────────────────
step_12_validate() {
    log "[12/12] Validation complète de l'environnement WSL2..."

    PASS=0
    FAIL=0

    check() {
        local name=$1
        local cmd=$2
        if eval "$cmd" &>/dev/null; then
            local ver
            ver=$(eval "$cmd" 2>&1 | head -1)
            echo -e "  ${GREEN}✓ ${name}${NC} : ${ver}"
            ((PASS++))
        else
            echo -e "  ${RED}✗ ${name} — NON TROUVÉ${NC}"
            ((FAIL++))
        fi
    }

    check "git"      "git --version"
    check "curl"     "curl --version"
    check "jq"       "jq --version"
    check "kubectl"  "kubectl version --client 2>/dev/null || kubectl version --client --short"
    check "helm"     "helm version --short"
    check "k3d"      "k3d version"
    check "tofu"     "tofu --version"
    check "ansible"  "ansible --version"
    check "argocd"   "argocd version --client"
    check "trivy"    "trivy --version"
    check "cosign"   "cosign version"
    check "k9s"      "k9s version --short"
    check "stern"    "stern --version"
    check "yq"       "yq --version"

    echo ""
    echo "  Réussis : ${PASS} / Échoués : ${FAIL}"

    if [ $FAIL -eq 0 ]; then
        echo -e "  ${GREEN}✓ Environnement WSL2 prêt. Lancer create-cluster.sh${NC}"
        return 0
    else
        echo -e "  ${RED}✗ ${FAIL} outil(s) manquant(s). Relancer les étapes concernées.${NC}"
        return 1
    fi
}

# ────────────────────────────────────────────────
# Dispatcher
# ────────────────────────────────────────────────
ALL_STEPS=(
    step_01_update_system
    step_02_install_base_tools
    step_03_install_kubectl
    step_04_install_helm
    step_05_install_k3d
    step_06_install_mise
    step_07_install_opentofu
    step_08_install_ansible
    step_09_install_argocd_cli
    step_10_install_security_tools
    step_11_install_k9s_and_tools
    step_12_validate
)

if [ "$STEP" = "all" ]; then
    for s in "${ALL_STEPS[@]}"; do
        "$s"
    done
elif declare -f "$STEP" > /dev/null; then
    "$STEP"
else
    err "Étape inconnue : $STEP"
    echo "Étapes disponibles : ${ALL_STEPS[*]}"
    exit 1
fi
