#!/bin/bash
# ============================================================
# health-check.sh — Validation complète de l'environnement
# CapabilityForge / Tahar ARIB
#
# Usage : bash health-check.sh
# Exécutable à tout moment pendant la formation
# pour diagnostiquer rapidement un problème.
# ============================================================

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0
FAIL=0
WARN=0

# ────────────────────────────────────────────────
# Fonctions utilitaires
# ────────────────────────────────────────────────
check() {
    local name=$1
    local cmd=$2
    local expected_version=${3:-}
    if eval "$cmd" &>/dev/null; then
        local ver
        ver=$(eval "$cmd" 2>&1 | head -1)
        printf "  ${GREEN}✓${NC} %-20s %s\n" "$name" "$ver"
        ((PASS++)) || true
    else
        printf "  ${RED}✗${NC} %-20s ${RED}NON TROUVÉ${NC}\n" "$name"
        ((FAIL++)) || true
    fi
}

check_soft() {
    # Avertissement non bloquant
    local name=$1
    local cmd=$2
    local hint=$3
    if eval "$cmd" &>/dev/null; then
        local ver
        ver=$(eval "$cmd" 2>&1 | head -1)
        printf "  ${GREEN}✓${NC} %-20s %s\n" "$name" "$ver"
        ((PASS++)) || true
    else
        printf "  ${YELLOW}⚠${NC} %-20s ${YELLOW}non trouvé — %s${NC}\n" "$name" "$hint"
        ((WARN++)) || true
    fi
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}=== $* ===${NC}"
}

# ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Health Check — Ingénierie DevOps 3 jours   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"

# ────────────────────────────────────────────────
section "CLIs fondamentaux"
check "git"         "git --version"
check "curl"        "curl --version"
check "jq"          "jq --version"
check "yq"          "yq --version"
check "make"        "make --version"

section "Conteneurs & Kubernetes"
check "docker"      "docker info"
check "kubectl"     "kubectl version --client 2>/dev/null || kubectl version --client --short"
check "helm"        "helm version --short"
check "k3d"         "k3d version"
check "k9s"         "k9s version --short 2>/dev/null"
check "stern"       "stern --version"

section "IaC & Configuration"
check "tofu"        "tofu --version"
check "ansible"     "ansible --version"

section "GitOps & Sécurité"
check "argocd"      "argocd version --client 2>/dev/null"
check "trivy"       "trivy --version"
check "cosign"      "cosign version 2>/dev/null"

section "Gestionnaire de versions"
check_soft "mise"   "mise --version" "optionnel — step_06 de install-wsl2.sh"

# ────────────────────────────────────────────────
section "Cluster Kubernetes"

check "cluster up" "kubectl get nodes"

# Vérifier exactement 4 nodes (1 control plane + 3 agents)
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODE_COUNT" -eq 4 ]; then
    printf "  ${GREEN}✓${NC} %-20s %s nodes\n" "4 nodes attendus" "$NODE_COUNT"
    ((PASS++)) || true
else
    printf "  ${RED}✗${NC} %-20s attendu: 4, trouvé: %s\n" "4 nodes attendus" "$NODE_COUNT"
    ((FAIL++)) || true
fi

# Vérifier les labels role=app
APP_NODES=$(kubectl get nodes -l role=app --no-headers 2>/dev/null | wc -l)
if [ "$APP_NODES" -eq 2 ]; then
    printf "  ${GREEN}✓${NC} %-20s agent-0, agent-1\n" "nodes role=app (2)"
    ((PASS++)) || true
else
    printf "  ${YELLOW}⚠${NC} %-20s attendu: 2, trouvé: %s\n" "nodes role=app" "$APP_NODES"
    ((WARN++)) || true
fi

# Vérifier le label role=infra
INFRA_NODES=$(kubectl get nodes -l role=infra --no-headers 2>/dev/null | wc -l)
if [ "$INFRA_NODES" -eq 1 ]; then
    printf "  ${GREEN}✓${NC} %-20s agent-2\n" "node role=infra (1)"
    ((PASS++)) || true
else
    printf "  ${YELLOW}⚠${NC} %-20s attendu: 1, trouvé: %s\n" "node role=infra" "$INFRA_NODES"
    ((WARN++)) || true
fi

# Vérifier le taint sur agent-2
TAINT=$(kubectl get node k3d-spring-petclinic-agent-2 \
    -o jsonpath='{.spec.taints[?(@.key=="dedicated")].effect}' 2>/dev/null)
if [ "$TAINT" = "NoSchedule" ]; then
    printf "  ${GREEN}✓${NC} %-20s dedicated=infra:NoSchedule\n" "taint infra"
    ((PASS++)) || true
else
    printf "  ${YELLOW}⚠${NC} %-20s taint dedicated=infra:NoSchedule absent\n" "taint infra"
    ((WARN++)) || true
fi

# ────────────────────────────────────────────────
section "Registry local"

if curl -sf "http://registry.k3d.localhost:5000/v2/" > /dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} %-20s http://registry.k3d.localhost:5000\n" "registry accessible"
    ((PASS++)) || true
else
    printf "  ${RED}✗${NC} %-20s ${RED}http://registry.k3d.localhost:5000 inaccessible${NC}\n" "registry"
    ((FAIL++)) || true
fi

# Vérifier /etc/hosts
if grep -q "registry.k3d.localhost" /etc/hosts; then
    printf "  ${GREEN}✓${NC} %-20s /etc/hosts\n" "entrée DNS locale"
    ((PASS++)) || true
else
    printf "  ${YELLOW}⚠${NC} %-20s registry.k3d.localhost absent de /etc/hosts\n" "entrée DNS locale"
    ((WARN++)) || true
fi

# ────────────────────────────────────────────────
# Résultat final
# ────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ${GREEN}Réussis  :${NC} %d\n" "$PASS"
printf "  ${YELLOW}Warnings :${NC} %d\n" "$WARN"
printf "  ${RED}Échoués  :${NC} %d\n" "$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ Environnement 100% opérationnel${NC}"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo -e "  ${YELLOW}⚠ Environnement opérationnel avec ${WARN} avertissement(s)${NC}"
    exit 0
else
    echo -e "  ${RED}✗ ${FAIL} problème(s) bloquant(s) à corriger${NC}"
    echo ""
    echo "  → Relancer les étapes manquantes dans install-wsl2.sh"
    echo "  → ou : bash create-cluster.sh  si le cluster est absent"
    exit $FAIL
fi
