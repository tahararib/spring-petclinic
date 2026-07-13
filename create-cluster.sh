#!/bin/bash
# ============================================================
# create-cluster.sh — Cluster k3d de formation
# CapabilityForge / Tahar ARIB
#
# Topologie :
#   1 control plane
#   agent-0  role=app
#   agent-1  role=app
#   agent-2  role=infra  (taint NoSchedule)
#   + registry local : registry.k3d.localhost:5000
#
# Usage :
#   bash create-cluster.sh
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}$*${NC}"; }
ok()   { echo -e "  ${GREEN}✓ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ $*${NC}"; }
err()  { echo -e "  ${RED}✗ $*${NC}"; exit 1; }

CLUSTER_NAME="spring-petclinic"
REGISTRY_NAME="registry.k3d.localhost"
REGISTRY_PORT="5000"

# ────────────────────────────────────────────────
# Prérequis
# ────────────────────────────────────────────────
for tool in k3d kubectl; do
    if ! command -v "$tool" &>/dev/null; then
        err "$tool n'est pas installé. Lancer install-wsl2.sh d'abord."
    fi
done

# Vérifier si le cluster existe déjà
if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
    warn "Le cluster '${CLUSTER_NAME}' existe déjà."
    warn "Pour le recréer : bash reset-cluster.sh"
    exit 0
fi

# ────────────────────────────────────────────────
# Étape 1 — Création du cluster k3d
# ────────────────────────────────────────────────
log "[1/4] Création du cluster k3d '${CLUSTER_NAME}'..."
log "      (1 control plane + 3 agents + registry local)"

k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --agents 3 \
    --k3s-arg "--node-label=role=app@agent:0" \
    --k3s-arg "--node-label=role=app@agent:1" \
    --k3s-arg "--node-label=role=infra@agent:2" \
    --registry-create "${REGISTRY_NAME}:${REGISTRY_PORT}" \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer" \
    --wait

ok "Cluster créé"

# ────────────────────────────────────────────────
# Étape 2 — Taint sur le node infra
# Seuls les pods avec la toleration dedicated=infra:NoSchedule
# seront schedulés sur agent-2 (stack PLGT : Prometheus, Loki, Tempo)
# ────────────────────────────────────────────────
log "[2/4] Ajout du taint NoSchedule sur agent-2 (role=infra)..."

kubectl taint node "k3d-${CLUSTER_NAME}-agent-2" \
    dedicated=infra:NoSchedule

ok "Taint appliqué sur k3d-${CLUSTER_NAME}-agent-2"

# ⚠️  NOTE POUR LES LABS CH.12 J3 — Stack PLGT (Prometheus, Loki, Grafana, Tempo)
# Ce taint repousse TOUS les pods sans toleration explicite.
# Les Helm charts de monitoring DOIVENT inclure dans leurs values.yaml :
#
#   tolerations:
#     - key: dedicated
#       operator: Equal
#       value: infra
#       effect: NoSchedule
#   nodeSelector:
#     role: infra
#
# Concerné : kube-prometheus-stack, loki-stack (Promtail/Alloy inclus), tempo
# Sans ces blocs, les pods de monitoring restent en Pending indéfiniment.

# ────────────────────────────────────────────────
# Étape 3 — /etc/hosts pour le registry local
# ────────────────────────────────────────────────
log "[3/4] Vérification de l'entrée /etc/hosts pour registry.k3d.localhost..."

if grep -q "registry.k3d.localhost" /etc/hosts; then
    ok "Entrée /etc/hosts déjà présente"
else
    echo "127.0.0.1 registry.k3d.localhost" | sudo tee -a /etc/hosts > /dev/null
    ok "Entrée ajoutée : 127.0.0.1 registry.k3d.localhost"
fi

# ────────────────────────────────────────────────
# Étape 4 — Validation
# ────────────────────────────────────────────────
log "[4/4] Validation du cluster..."

echo ""
kubectl get nodes -o wide
echo ""

# Vérifier l'accès au registry
if curl -sf "http://${REGISTRY_NAME}:${REGISTRY_PORT}/v2/" > /dev/null 2>&1; then
    ok "Registry local accessible : http://${REGISTRY_NAME}:${REGISTRY_PORT}"
else
    warn "Registry local non encore accessible — attendre quelques secondes et tester : curl http://${REGISTRY_NAME}:${REGISTRY_PORT}/v2/"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Cluster '${CLUSTER_NAME}' prêt                "
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Registry local  : ${REGISTRY_NAME}:${REGISTRY_PORT}    "
echo "║  Load Balancer   : http://localhost (port 80)               ║"
echo "║  HTTPS           : https://localhost (port 443)             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Topology :                                                  ║"
echo "║    control-plane : orchestration seule                       ║"
echo "║    agent-0       : role=app                                  ║"
echo "║    agent-1       : role=app                                  ║"
echo "║    agent-2       : role=infra + taint NoSchedule             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Prochain : bash health-check.sh                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
