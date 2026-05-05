#!/usr/bin/env bash
# dev.sh — manage the airgradient collector stack with podman compose
#
# Usage:
#   ./dev.sh           — build and start everything, logs → logs/dev.log
#   ./dev.sh restart   — rebuild and restart the collector
#   ./dev.sh logs      — tail logs/dev.log
#   ./dev.sh stop      — stop everything

set -euo pipefail

COMPOSE='podman compose'
LOG_FILE='logs/dev.log'

cmd=${1:-up}

_start_log_follower() {
    mkdir -p logs
    pkill -f "podman compose logs -f" 2>/dev/null || true
    $COMPOSE logs -f collector >> "$LOG_FILE" 2>&1 &
    echo "→ Logs writing to $LOG_FILE (tail with: ./dev.sh logs)"
}

case "$cmd" in
  up)
    echo '→ Starting stack...'
    $COMPOSE up -d --build
    _start_log_follower
    ;;

  restart)
    echo '→ Rebuilding and restarting collector...'
    $COMPOSE up -d --build collector
    _start_log_follower
    ;;

  logs)
    if [ ! -f "$LOG_FILE" ]; then
        echo "→ No log file yet. Run ./dev.sh up first."
        exit 1
    fi
    tail -f "$LOG_FILE"
    ;;

  stop)
    echo '→ Stopping stack...'
    pkill -f "podman compose logs -f" 2>/dev/null || true
    $COMPOSE down
    ;;

  *)
    echo "Usage: $0 [up|restart|logs|stop]"
    exit 1
    ;;
esac