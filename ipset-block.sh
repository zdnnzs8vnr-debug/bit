#!/usr/bin/env bash
# ============================================================
#  GUSTAVOEURO · ipset-block.sh
#  Banna a livello kernel gli IP che abusano del nodo.
#  Uso:  sudo ./ipset-block.sh install
#        sudo ./ipset-block.sh ban 1.2.3.4
#        sudo ./ipset-block.sh unban 1.2.3.4
#        sudo ./ipset-block.sh list
#        sudo ./ipset-block.sh watch      # tail nginx + ban automatico
#        sudo ./ipset-block.sh uninstall
# ============================================================
set -euo pipefail

SET4="ge_block4"
SET6="ge_block6"
CHAIN="GE_BLOCK"
LOG="/var/log/nginx/access.log"
THRESHOLD="${THRESHOLD:-120}"     # richieste
WINDOW="${WINDOW:-60}"            # secondi
BANTIME="${BANTIME:-86400}"       # 24h

need_root(){ [ "$(id -u)" -eq 0 ] || { echo "serve root"; exit 1; }; }

install_all(){
  need_root
  command -v ipset >/dev/null || { apt-get update && apt-get install -y ipset iptables; }
  ipset create "$SET4" hash:ip timeout "$BANTIME" -exist
  ipset create "$SET6" hash:ip family inet6 timeout "$BANTIME" -exist
  iptables  -N "$CHAIN" 2>/dev/null || true
  iptables  -C INPUT -j "$CHAIN" 2>/dev/null || iptables -I INPUT 1 -j "$CHAIN"
  ip6tables -N "$CHAIN" 2>/dev/null || true
  ip6tables -C INPUT -j "$CHAIN" 2>/dev/null || ip6tables -I INPUT 1 -j "$CHAIN"
  iptables  -A "$CHAIN" -m set --match-set "$SET4" src -j DROP
  ip6tables -A "$CHAIN" -m set --match-set "$SET6" src -j DROP
  mkdir -p /etc/iptables
  ipset save > /etc/iptables/ipset.rules
  iptables-save > /etc/iptables/rules.v4
  ip6tables-save > /etc/iptables/rules.v6
  echo "[OK] ipset + catene installate (soglia ${THRESHOLD}/${WINDOW}s, ban ${BANTIME}s)"
}

uninstall_all(){
  need_root
  iptables  -D INPUT -j "$CHAIN" 2>/dev/null || true
  ip6tables -D INPUT -j "$CHAIN" 2>/dev/null || true
  iptables  -F "$CHAIN" 2>/dev/null || true
  ip6tables -F "$CHAIN" 2>/dev/null || true
  iptables  -X "$CHAIN" 2>/dev/null || true
  ip6tables -X "$CHAIN" 2>/dev/null || true
  ipset destroy "$SET4" 2>/dev/null || true
  ipset destroy "$SET6" 2>/dev/null || true
  echo "[OK] rimosso"
}

ban(){ need_root; ipset add "$SET4" "$1" timeout "$BANTIME" -exist; echo "[BAN] $1"; }
unban(){ need_root; ipset del "$SET4" "$1" 2>/dev/null || true; echo "[UNBAN] $1"; }
list(){ ipset list "$SET4" | sed -n '1,40p'; }

watch(){
  need_root
  command -v tail >/dev/null || exit 1
  declare -A hits
  echo "[WATCH] $LOG · soglia ${THRESHOLD}/${WINDOW}s"
  tail -F "$LOG" 2>/dev/null | while read -r line; do
    ip="$(echo "$line" | grep -oE '^[0-9a-fA-F:.]+' | head -1)"
    [ -z "$ip" ] && continue
    now="$(date +%s)"
    last="${hits[$ip]:-0}"
    if [ $(( now - last )) -gt "$WINDOW" ]; then
      hits[$ip]="$now"; cnt["$ip"]=1
    else
      cnt["$ip"]=$(( ${cnt[$ip]:-0} + 1 ))
      if [ "${cnt[$ip]}" -ge "$THRESHOLD" ]; then
        ipset add "$SET4" "$ip" timeout "$BANTIME" -exist 2>/dev/null || true
        logger -t ge-fw "ban $ip (${cnt[$ip]} req/${WINDOW}s)"
        cnt[$ip]=0
      fi
    fi
  done
}

case "${1:-install}" in
  install)   install_all ;;
  uninstall) uninstall_all ;;
  ban)       ban "${2:?ip mancante}" ;;
  unban)     unban "${2:?ip mancante}" ;;
  list)      list ;;
  watch)     watch ;;
  *) echo "uso: $0 {install|uninstall|ban <ip>|unban <ip>|list|watch}"; exit 1 ;;
esac
