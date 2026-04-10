#!/usr/bin/env bash
# openglg-config — service management
set -euo pipefail
cd "$(dirname "$0")"

# Service startup order
CORE_SERVICES=(caddy authelia postgres homer)
APP_SERVICES=(metabase openclaw remark42 umami)

up() {
  echo "=== Starting core services ==="
  for s in "${CORE_SERVICES[@]}"; do
    [ -f "$s/docker-compose.yml" ] && (cd "$s" && docker compose up -d) && echo "  ✓ $s"
  done
  echo ""
  echo "=== Starting app services ==="
  for s in "${APP_SERVICES[@]}"; do
    [ -f "$s/docker-compose.yml" ] && (cd "$s" && docker compose up -d) && echo "  ✓ $s"
  done
}

down() {
  echo "=== Stopping all services ==="
  for s in "${APP_SERVICES[@]}" "${CORE_SERVICES[@]}"; do
    [ -f "$s/docker-compose.yml" ] && (cd "$s" && docker compose down) && echo "  ✗ $s"
  done
}

restart() {
  down
  echo ""
  up
}

status() {
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo ""
  echo "=== Disk ==="
  df -h / | tail -1
  echo ""
  echo "=== Docker disk ==="
  docker system df 2>/dev/null
}

logs() {
  local svc="${1:-}"
  if [ -n "$svc" ]; then
    docker logs -f --tail 50 "$svc"
  else
    for s in "${CORE_SERVICES[@]}" "${APP_SERVICES[@]}"; do
      echo "--- $s ---"
      docker logs --tail 3 "$s" 2>/dev/null || echo "  (not running)"
    done
  fi
}

case "${1:-help}" in
  up)      up ;;
  down)    down ;;
  restart) restart ;;
  status)  status ;;
  logs)    logs "${2:-}" ;;
  *)
    echo "openglg-config service manager"
    echo ""
    echo "Usage: ./run.sh <command>"
    echo ""
    echo "  up        Start all services (core first, then apps)"
    echo "  down      Stop all services"
    echo "  restart   Stop then start all"
    echo "  status    Container status + disk usage"
    echo "  logs      All logs (summary) or: logs <container>"
    echo ""
    echo "Core: ${CORE_SERVICES[*]}"
    echo "Apps: ${APP_SERVICES[*]}"
    ;;
esac
