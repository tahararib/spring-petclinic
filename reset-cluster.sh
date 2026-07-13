#!/bin/bash
# ============================================================
# reset-cluster.sh — Reset complet du cluster (< 2 min)
# CapabilityForge / Tahar ARIB
#
# Filet de sécurité : si un participant casse son environnement
# Usage : bash reset-cluster.sh
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}$*${NC}"; }
ok()   { echo -e "  ${GREEN}✓ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ $*${NC}"; }

CLUSTER_NAME="spring-petclinic"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Reset cluster '${CLUSTER_NAME}'         "
echo "╠══════════════════════════════════════════╣"
echo "║  Durée estimée : < 2 minutes             ║"
echo "║  Toutes les ressources seront supprimées ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Confirmation interactive (bypass avec : FORCE=1 bash reset-cluster.sh)
if [ "${FORCE:-0}" != "1" ]; then
    read -r -p "  Confirmer la suppression et recréation du cluster ? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  Annulé."
        exit 0
    fi
fi

START_TIME=$(date +%s)

# ────────────────────────────────────────────────
log "[1/2] Suppression du cluster '${CLUSTER_NAME}'..."

if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER_NAME}"; then
    k3d cluster delete "${CLUSTER_NAME}"
    ok "Cluster supprimé"
else
    warn "Cluster '${CLUSTER_NAME}' n'existe pas — on passe directement à la création"
fi

# ────────────────────────────────────────────────
log "[2/2] Recréation du cluster..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/create-cluster.sh"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
ok "Cluster réinitialisé en ${ELAPSED}s"
echo ""
echo "  Lancer health-check.sh pour valider :"
echo "    bash health-check.sh"
