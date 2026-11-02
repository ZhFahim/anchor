#!/usr/bin/env bash
# =============================================================================
# Anchor+ on a small Linux server, in one line
# =============================================================================
# Made for the smallest (free tier) virtual servers: Oracle Cloud's
# VM.Standard.E2.1.Micro and Ampere A1, AWS t2/t3/t4g.micro, Google Cloud's
# e2-micro, a 1 GB VPS. Run as root on a fresh Ubuntu, Debian, Oracle Linux,
# Rocky/Alma/RHEL, Fedora, Amazon Linux or Arch server (amd64 or arm64), or
# on a Linux desktop such as Omarchy, with the port Anchor listens on:
#
#   curl -fsSL https://raw.githubusercontent.com/AlxndrJhn/anchor/main/install.sh | sudo PORT=3000 bash
#
# With a domain whose DNS already points at the server, Anchor gets HTTPS
# (a Let's Encrypt certificate, through Caddy) on ports 80 and 443:
#
#   curl -fsSL https://raw.githubusercontent.com/AlxndrJhn/anchor/main/install.sh | sudo DOMAIN=notes.example.com bash
#
# Without a domain of your own, DOMAIN=sslip.io takes a free hostname that
# maps to the server's IP, e.g. 203-0-113-7.sslip.io, and gets HTTPS for it:
#
#   curl -fsSL https://raw.githubusercontent.com/AlxndrJhn/anchor/main/install.sh | sudo DOMAIN=sslip.io bash
#
# It installs Docker if it's missing, adds swap when the server has less than
# 2 GB of memory, opens the port in the server's own firewall, and runs
# Anchor from /opt/anchor. Running it again updates Anchor to the newest
# release and keeps the notes, the settings and the domain.
#
# Settings (environment variables, all optional; remembered for later runs):
#   DOMAIN       serve https://DOMAIN, with Caddy on ports 80 and 443. sslip.io or nip.io:
#                a free hostname for the server's IP (<ip>.sslip.io), found
#                again on every run, so it follows a new IP
#   PORT         without DOMAIN, the port Anchor listens on (default 3000)
#   ANCHOR_TAG   the image tag, e.g. fork-preview or fork-0.17.2.36
#                (default fork-latest)
#   ANCHOR_DIR   where it lives (default /opt/anchor)
#   SWAP_SIZE    swap to add on a small server, in MB (default 2048; 0 adds none)
#
# Uninstalling is the same line with UNINSTALL=1. It backs everything up to
# a .tar in your home folder, then takes away all a run put here: Anchor and
# its notes, its images, ANCHOR_DIR, its firewall rules, its swap and the
# borgmatic configuration from the README (Docker stays):
#
#   curl -fsSL https://raw.githubusercontent.com/AlxndrJhn/anchor/main/install.sh | sudo UNINSTALL=1 bash
#
#   BACKUP_FILE  where the backup goes (default ~/anchor-backup-<date>.tar)
#   BACKUP=no    no backup
#   YES=1        no questions, for when there's no terminal to ask on
#
# More settings for Anchor itself (OIDC, sign up, ...) go in
# /opt/anchor/anchor.env, followed by `docker compose up -d` in /opt/anchor.
# =============================================================================

# Everything is in main, which runs on the last line, so a download cut short
# by `curl | bash` runs nothing at all.
set -euo pipefail

log() { printf '\033[1;34m[anchor]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[anchor]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[anchor]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# KEY=value in an env file: replace its line, or add one
set_env() {
  local file=$1 key=$2 value=$3
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

get_env() {
  local file=$1 key=$2
  if [ -f "$file" ]; then sed -n "s/^${key}=//p" "$file" | tail -n 1; fi
}

check_system() {
  [ "$(id -u)" -eq 0 ] || die "Run it as root: curl -fsSL <url> | sudo PORT=3000 bash"
  [ "$(uname -s)" = Linux ] || die "This is for Linux servers"
  case "$(uname -m)" in
    x86_64 | amd64 | aarch64 | arm64) ;;
    *) die "Anchor's image is for amd64 and arm64, not $(uname -m)" ;;
  esac
  [ -r /etc/os-release ] || die "Can't tell which Linux this is (no /etc/os-release)"
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID=${ID:-}
  OS_LIKE=${ID_LIKE:-}
}

install_docker() {
  if have docker && docker compose version >/dev/null 2>&1; then
    log "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo '') is installed"
  else
    log "Installing Docker..."
    case "$OS_ID" in
      ubuntu | debian | raspbian | fedora | centos | rhel)
        docker_script
        ;;
      ol | rocky | almalinux)
        # Docker's script doesn't know these; they take the CentOS packages
        dnf -y install dnf-plugins-core </dev/null
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin </dev/null
        ;;
      amzn)
        dnf -y install docker </dev/null
        install_compose_plugin
        ;;
      arch)
        pacman_docker
        ;;
      *)
        case " $OS_LIKE " in
          *" debian "* | *" ubuntu "* | *" fedora "* | *" rhel "*)
            docker_script
            ;;
          *" arch "*)
            pacman_docker
            ;;
          *) die "Install Docker with its Compose plugin, then run this again (no installer for '$OS_ID')" ;;
        esac
        ;;
    esac
  fi
  if have systemctl; then
    systemctl enable --now docker >/dev/null 2>&1 || true
  fi
  docker info >/dev/null 2>&1 || die "Docker is installed but isn't running"
  docker compose version >/dev/null 2>&1 || die "Docker's Compose plugin is missing"
}

# Docker's own install script. Its input isn't this script's: with
# `curl | bash`, that's the rest of this script.
docker_script() {
  local script
  script=$(mktemp)
  curl -fsSL https://get.docker.com -o "$script"
  sh "$script" </dev/null
  rm -f "$script"
}

# Arch (and Manjaro, EndeavourOS) package both. Arch doesn't do partial
# upgrades, so this updates the whole system; when that brings a new kernel,
# the running one's modules are gone and Docker can't start until a reboot.
pacman_docker() {
  # (A container-based VPS has no modules of its own to lose)
  local modules
  modules="/usr/lib/modules/$(uname -r)"
  [ -d "$modules" ] || modules=
  pacman -Syu --noconfirm --needed docker docker-compose </dev/null
  if [ -n "$modules" ] && [ ! -d "$modules" ]; then
    die "The system update brought a new kernel: reboot, then run this again"
  fi
}

# Amazon Linux packages Docker without Compose: take it from its releases
install_compose_plugin() {
  local arch dir=/usr/local/lib/docker/cli-plugins
  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    *) arch=aarch64 ;;
  esac
  mkdir -p "$dir"
  curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${arch}" \
    -o "$dir/docker-compose"
  chmod +x "$dir/docker-compose"
}

# Postgres, the API and the web app need a little more than 1 GB at times
# (imports, reading the text in pictures); swap keeps them from being killed.
add_swap() {
  local mem_mb swap_mb free_mb size=${SWAP_SIZE:-2048}
  mem_mb=$(awk '/^MemTotal:/ {print int($2 / 1024)}' /proc/meminfo)
  swap_mb=$(awk '/^SwapTotal:/ {print int($2 / 1024)}' /proc/meminfo)
  LOW_MEMORY=0
  [ "$mem_mb" -lt 2000 ] && LOW_MEMORY=1
  if [ "$LOW_MEMORY" = 0 ] || [ "$size" -le 0 ] || [ "$swap_mb" -ge 1000 ]; then
    return
  fi
  if [ -e /swapfile ]; then
    warn "/swapfile is there but not in use; leaving it alone"
    return
  fi
  free_mb=$(df -Pm / | awk 'NR == 2 {print $4}')
  if [ "$free_mb" -lt $((size + 3072)) ]; then
    warn "Not enough disk for ${size} MB of swap; Anchor may run short of memory"
    return
  fi
  log "Adding ${size} MB of swap (the server has ${mem_mb} MB of memory)..."
  : >/swapfile
  chmod 600 /swapfile
  # On btrfs (Arch's usual root) a swap file must not be copy-on-write, which
  # can only be turned off while the file is still empty
  if [ "$(stat -f -c %T /)" = btrfs ]; then
    chattr +C /swapfile 2>/dev/null || true
  fi
  if ! fallocate -l "${size}M" /swapfile 2>/dev/null; then
    dd if=/dev/zero of=/swapfile bs=1M count="$size" status=none
  fi
  mkswap /swapfile >/dev/null
  if ! swapon /swapfile 2>/dev/null; then
    rm -f /swapfile
    warn "This file system can't hold a swap file; Anchor may run short of memory"
    return
  fi
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  # Use it for what's idle, not as memory
  echo 'vm.swappiness=10' >/etc/sysctl.d/90-anchor-swap.conf
  sysctl -q -p /etc/sysctl.d/90-anchor-swap.conf || true
}

load_settings() {
  ANCHOR_DIR=${ANCHOR_DIR:-/opt/anchor}
  mkdir -p "$ANCHOR_DIR"
  chmod 700 "$ANCHOR_DIR"
  CONF="$ANCHOR_DIR/.env"
  ENV_FILE="$ANCHOR_DIR/anchor.env"

  # What an earlier run set, unless given again (DOMAIN= drops the domain)
  OLD_HOST=$(get_env "$CONF" HOST)
  DOMAIN=${DOMAIN-$(get_env "$CONF" DOMAIN)}
  PORT=${PORT:-$(get_env "$CONF" PORT)}
  PORT=${PORT:-3000}
  ANCHOR_TAG=${ANCHOR_TAG:-$(get_env "$CONF" ANCHOR_TAG)}
  ANCHOR_TAG=${ANCHOR_TAG:-fork-latest}
  DOMAIN=${DOMAIN#http://}
  DOMAIN=${DOMAIN#https://}
  DOMAIN=${DOMAIN%%/*}
  PUBLIC_IP=$(public_ip)

  # A desktop (Omarchy, or any Linux that starts to a graphical login) is
  # likely at home, behind a router whose IP is the public one: without a
  # domain, Anchor is at the desktop's address on the local network
  DESKTOP=0
  ADDRESS=$PUBLIC_IP
  if have systemctl && [ "$(systemctl get-default 2>/dev/null)" = graphical.target ]; then
    DESKTOP=1
    ADDRESS=$(local_ip)
    ADDRESS=${ADDRESS:-$PUBLIC_IP}
  fi

  # HOST is the name Anchor is served at: the domain, or for sslip.io and
  # nip.io, the server's IP with dashes in front of it
  HOST=$DOMAIN
  case "$DOMAIN" in
    sslip.io | nip.io)
      is_public_ipv4 "$PUBLIC_IP" ||
        die "DOMAIN=$DOMAIN needs the server's public IPv4 address, and '$PUBLIC_IP' isn't one"
      HOST="$(printf '%s' "$PUBLIC_IP" | tr . -).$DOMAIN"
      ;;
  esac

  touch "$CONF"
  chmod 600 "$CONF"
  set_env "$CONF" DOMAIN "$DOMAIN"
  set_env "$CONF" HOST "$HOST"
  set_env "$CONF" PORT "$PORT"
  set_env "$CONF" ANCHOR_TAG "$ANCHOR_TAG"
}

write_anchor_env() {
  if [ ! -f "$ENV_FILE" ]; then
    cat >"$ENV_FILE" <<'EOF'
# Anchor's settings (see "Configure environment" in the README). After a
# change, run `docker compose up -d` in this folder. install.sh keeps what's
# here, and only sets APP_URL when the domain changes.
EOF
  fi
  chmod 600 "$ENV_FILE"
  # Set once: Postgres keeps the password it was first started with
  if [ -z "$(get_env "$ENV_FILE" PG_PASSWORD)" ]; then
    set_env "$ENV_FILE" PG_PASSWORD "$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  fi
  local app_url
  app_url=$(get_env "$ENV_FILE" APP_URL)
  if [ -n "$HOST" ]; then
    set_env "$ENV_FILE" APP_URL "https://$HOST"
  elif [ -z "$app_url" ] || { [ -n "$OLD_HOST" ] && [ "$app_url" = "https://$OLD_HOST" ]; } ||
    printf '%s' "$app_url" | grep -Eq '^http://[0-9.]+:[0-9]+$'; then
    # An IP address and port, as an earlier run set it: follow a new address
    set_env "$ENV_FILE" APP_URL "http://$ADDRESS:$PORT"
  fi
  # Search by what pictures show loads a ~380 MB model: too much for 1 GB
  if [ "$LOW_MEMORY" = 1 ] && [ -z "$(get_env "$ENV_FILE" PICTURE_SEARCH)" ]; then
    set_env "$ENV_FILE" PICTURE_SEARCH off
  fi
}

write_compose() {
  local ports caddy=
  if [ -n "$DOMAIN" ]; then
    ports=
    caddy=$(
      cat <<'EOF'

  # HTTPS for HOST, with a certificate from Let's Encrypt
  caddy:
    image: caddy:2-alpine
    container_name: anchor-plus-caddy
    restart: unless-stopped
    command: caddy reverse-proxy --from ${HOST} --to anchor-plus:3000
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - caddy_data:/data
      - caddy_config:/config
    logging:
      driver: local
    depends_on:
      - anchor-plus
EOF
    )
  else
    ports=$(
      cat <<'EOF'

    ports:
      - "${PORT}:3000"
EOF
    )
  fi
  cat >"$ANCHOR_DIR/docker-compose.yml" <<EOF
# Written by install.sh, which rewrites it on every run: settings go in
# anchor.env (Anchor's own) and .env (DOMAIN, PORT, ANCHOR_TAG; HOST follows
# from DOMAIN).
name: anchor-plus

services:
  anchor-plus:
    image: ghcr.io/alxndrjhn/anchor:\${ANCHOR_TAG}
    container_name: anchor-plus
    restart: unless-stopped
    # Time to shut Postgres down cleanly
    stop_grace_period: 1m
    env_file: anchor.env${ports}
    volumes:
      - anchor_plus_data:/data
    # Rotated logs, so they can't fill a small disk
    logging:
      driver: local${caddy}

volumes:
  anchor_plus_data:
EOF
  if [ -n "$DOMAIN" ]; then
    printf '  caddy_data:\n  caddy_config:\n' >>"$ANCHOR_DIR/docker-compose.yml"
  fi
}

# The server's own firewall. Oracle's Ubuntu images reject everything but SSH
# in iptables; Oracle Linux and RHEL have firewalld.
open_ports() {
  local port rule
  for port in $(ports_for "$DOMAIN" "$PORT"); do
    if have ufw && ufw status 2>/dev/null | grep -q '^Status: active'; then
      ufw allow "$port/tcp" >/dev/null
      opened "ufw:$port"
    elif have firewall-cmd && firewall-cmd --state >/dev/null 2>&1; then
      firewall-cmd -q --permanent --add-port="$port/tcp"
      opened "firewalld:$port"
    elif have iptables && iptables -S INPUT 2>/dev/null | grep -q -- '-j REJECT'; then
      rule=$(iptables_rule "$port")
      # shellcheck disable=SC2086
      iptables -C INPUT $rule 2>/dev/null || iptables -I INPUT 1 $rule
      # And after a reboot: into the saved rules, ahead of the REJECT. Not
      # with iptables-save, which would save Docker's rules too.
      if [ -f "$IPTABLES_RULES" ] && ! grep -qF -- "-A INPUT $rule" "$IPTABLES_RULES"; then
        sed -i "0,/^-A INPUT .*-j REJECT/s//-A INPUT $rule\n&/" "$IPTABLES_RULES"
      fi
      opened "iptables:$port"
    fi
  done
  if have firewall-cmd && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd -q --reload
  fi
  # ufw-docker (Omarchy has it) keeps everyone but this machine away from
  # containers until a route rule lets them in. It sees the traffic after
  # Docker has passed it on, so the rule is for the container's port.
  local forward
  if have ufw && grep -q '^# BEGIN UFW AND DOCKER' /etc/ufw/after.rules 2>/dev/null; then
    for forward in $(forwards_for "$DOMAIN"); do
      ufw route allow proto "${forward%%:*}" from any to any port "${forward#*:}" >/dev/null
      opened "ufw-route:$forward"
    done
  fi
}

IPTABLES_RULES=/etc/iptables/rules.v4

# The ports Anchor is reached at, and the containers' ports behind them
ports_for() { if [ -n "$1" ]; then echo "80 443"; else echo "$2"; fi; }
forwards_for() { if [ -n "$1" ]; then echo "tcp:80 tcp:443 udp:443"; else echo "tcp:3000"; fi; }
iptables_rule() { echo "-p tcp -m state --state NEW -m tcp --dport $1 -j ACCEPT"; }

# Each firewall rule a run added, in .env, so an uninstall takes them all
# away again, also those for an earlier PORT or DOMAIN
opened() {
  local list
  list=$(get_env "$CONF" OPENED)
  case ",$list," in *",$1,"*) return ;; esac
  set_env "$CONF" OPENED "${list:+$list,}$1"
}

# Takes away a rule opened() noted: kind:port, or ufw-route:proto:port
close_rule() {
  local kind=${1%%:*} what=${1#*:} rule
  case "$kind" in
    ufw)
      have ufw && ufw delete allow "$what/tcp" >/dev/null 2>&1
      ;;
    firewalld)
      have firewall-cmd && firewall-cmd -q --permanent --remove-port="$what/tcp" 2>/dev/null
      ;;
    iptables)
      rule=$(iptables_rule "$what")
      # shellcheck disable=SC2086
      have iptables && iptables -D INPUT $rule 2>/dev/null
      [ -f "$IPTABLES_RULES" ] && sed -i "\|^-A INPUT $rule\$|d" "$IPTABLES_RULES"
      ;;
    ufw-route)
      have ufw && ufw route delete allow proto "${what%%:*}" from any to any port "${what#*:}" >/dev/null 2>&1
      ;;
  esac
  return 0
}

# The address the internet sees (a cloud server's own is a private one)
public_ip() {
  curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null ||
    hostname -I 2>/dev/null | awk '{print $1}'
}

# This machine's address on the local network: the one it reaches the
# internet from
local_ip() {
  ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p'
}

# An IPv4 address the internet can reach: not private, shared (CGNAT),
# loopback or link-local
is_public_ipv4() {
  local a b c d n
  IFS=. read -r a b c d <<<"$1"
  for n in "$a" "$b" "$c" "$d"; do
    case "$n" in '' | *[!0-9]*) return 1 ;; esac
    [ "$n" -le 255 ] || return 1
  done
  case "$a" in
    0 | 10 | 127) return 1 ;;
    100) [ "$b" -lt 64 ] || [ "$b" -gt 127 ] ;;
    169) [ "$b" -ne 254 ] ;;
    172) [ "$b" -lt 16 ] || [ "$b" -gt 31 ] ;;
    192) [ "$b" -ne 168 ] ;;
    *) [ "$a" -lt 224 ] ;;
  esac
}

# Earlier installs ran as the Compose project "anchor", with the original
# Anchor's container and volume names. Stop them and copy the notes into
# anchor-plus's own volume, before the compose file that names them is
# rewritten: if this fails, running the script again starts over. The old
# volume is kept.
OLD_VOLUME=
move_to_own_name() {
  local compose="$ANCHOR_DIR/docker-compose.yml" new=anchor-plus_anchor_plus_data
  [ -f "$compose" ] && grep -qx 'name: anchor' "$compose" || return 0
  log "Moving Anchor+ to its own names (anchor-plus), so it can run next to the original Anchor..."
  (cd "$ANCHOR_DIR" && docker compose down)
  OLD_VOLUME=$(docker volume ls -q \
    --filter label=com.docker.compose.project=anchor \
    --filter label=com.docker.compose.volume=anchor_data)
  [ -n "$OLD_VOLUME" ] || return 0
  # With Compose's labels, so it takes the volume as its own
  docker volume create \
    --label com.docker.compose.project=anchor-plus \
    --label com.docker.compose.volume=anchor_plus_data \
    "$new" >/dev/null
  docker run --rm -v "$OLD_VOLUME:/from:ro" -v "$new:/to" --entrypoint cp \
    "ghcr.io/alxndrjhn/anchor:$ANCHOR_TAG" -a /from/. /to/
}

start_anchor() {
  cd "$ANCHOR_DIR"
  log "Downloading Anchor (ghcr.io/alxndrjhn/anchor:$ANCHOR_TAG)..."
  docker compose pull -q
  log "Starting Anchor..."
  docker compose up -d --remove-orphans
  # The image before this one, which a small disk can do without
  docker image prune -f >/dev/null 2>&1 || true

  log "Waiting for Anchor to start (a first start takes a minute or two)..."
  wait_for_anchor anchor-plus
}

# In ANCHOR_DIR, with Anchor's service: anchor-plus, or anchor before the move
wait_for_anchor() {
  local tries=90
  while [ "$tries" -gt 0 ]; do
    tries=$((tries - 1))
    if docker compose exec -T "$1" curl -fsS http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done
  die "Anchor didn't answer in 3 minutes. Its log: cd $ANCHOR_DIR && docker compose logs $1"
}

report() {
  local url
  if [ -n "$HOST" ]; then url="https://$HOST"; else url="http://$ADDRESS:$PORT"; fi
  echo
  log "Anchor is running: $url"
  echo
  echo "  Sign up right away: the first account is the admin."
  if [ "$DESKTOP" = 1 ] && [ -z "$HOST" ]; then
    echo "  On this computer: http://localhost:$PORT. Phones and other computers"
    echo "  on the same network: $url (the router may give this"
    echo "  computer another address one day; run this again then)."
    echo "  Plain HTTP: fine at home, but don't open the port on your router."
  elif [ "$HOST" != "$DOMAIN" ]; then
    echo "  $HOST is a free hostname for $PUBLIC_IP. If the"
    echo "  IP changes, run this again: Anchor moves to the new hostname, and the"
    echo "  apps need it too."
    echo "  The certificate comes once ports 80 and 443 are open."
  elif [ -n "$HOST" ]; then
    echo "  The certificate comes once $HOST points at $PUBLIC_IP and ports 80"
    echo "  and 443 are open."
  else
    echo "  Over plain HTTP, passwords and notes cross the internet unencrypted."
    echo "  For HTTPS, run this again with DOMAIN=sslip.io (a free hostname for"
    echo "  $PUBLIC_IP) or DOMAIN=<your domain>."
  fi
  echo
  if [ "$DESKTOP" = 1 ]; then
    if [ -n "$HOST" ]; then
      echo "  Your router must forward ports 80 and 443 to this computer ($ADDRESS)."
      echo
    fi
  else
    echo "  Your cloud's firewall must let the port in too (only the server's own"
    echo "  firewall was opened):"
    echo "    Oracle Cloud  VCN > Security List > Ingress rule, TCP, source 0.0.0.0/0"
    echo "    AWS           the instance's security group > Inbound rule"
    echo "    Google Cloud  VPC network > Firewall > rule for the instance"
    echo
  fi
  echo "  Update later:  run the same command again"
  echo "  Settings:      $ENV_FILE, then: cd $ANCHOR_DIR && docker compose up -d"
  echo "  Backup:        cd $ANCHOR_DIR && docker compose exec -T anchor-plus backup > anchor-backup-\$(date +%F).tar"
  echo "  Daily backups: with borgmatic, see https://github.com/AlxndrJhn/anchor#backing-up-with-borgmatic"
  echo
  if [ -n "$OLD_VOLUME" ]; then
    echo "  The notes were copied to a new volume. Once you've checked that"
    echo "  they're all there, delete the old one: docker volume rm $OLD_VOLUME"
    echo
  fi
}

# Asks on the terminal: under `curl | bash`, the script's input is the script
ask() {
  local answer=
  printf '%s ' "$1" >/dev/tty
  read -r answer </dev/tty || true
  printf '%s' "$answer"
}

# UNINSTALL=1: takes away all a run put here, after a backup
uninstall() {
  ANCHOR_DIR=${ANCHOR_DIR:-/opt/anchor}
  CONF="$ANCHOR_DIR/.env"
  local compose="$ANCHOR_DIR/docker-compose.yml" swap_conf=/etc/sysctl.d/90-anchor-swap.conf
  local borg=/etc/borgmatic.d/anchor.yaml service volumes rules rule domain port ports=''
  local home=${HOME:-/root} backup_file='' interactive=0 images old_volume
  [ -f "$compose" ] || die "Anchor+ isn't installed in $ANCHOR_DIR (it has no docker-compose.yml)"
  { have docker && docker info >/dev/null 2>&1; } || die "Docker isn't running, and Anchor+ needs it to be backed up and removed"
  cd "$ANCHOR_DIR"
  service=$(docker compose config --services 2>/dev/null | grep -vx caddy | head -n 1) || true
  [ -n "$service" ] || die "Can't read $compose"
  volumes=$(docker compose config --volumes 2>/dev/null | tr '\n' ' ')

  # The firewall rules runs noted, and, for an install from before they did,
  # those its settings opened, in whichever firewall is there
  domain=$(get_env "$CONF" DOMAIN)
  port=$(get_env "$CONF" PORT)
  rules=$(get_env "$CONF" OPENED | tr , ' ')
  if [ -z "$rules" ]; then
    for port in $(ports_for "$domain" "${port:-3000}"); do
      rules="$rules ufw:$port firewalld:$port iptables:$port"
    done
    if grep -q '^# BEGIN UFW AND DOCKER' /etc/ufw/after.rules 2>/dev/null; then
      for rule in $(forwards_for "$domain"); do rules="$rules ufw-route:$rule"; done
    fi
  fi
  for rule in $rules; do
    case "$rule" in ufw:* | firewalld:* | iptables:*) ports="$ports ${rule#*:}" ;; esac
  done
  ports=$(printf '%s\n' "$ports" | tr ' ' '\n' | sed '/^$/d' | sort -un | tr '\n' ' ')

  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
    home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  fi
  case "${BACKUP:-yes}" in
    0 | no | off | false) ;;
    *) backup_file=${BACKUP_FILE:-$home/anchor-backup-$(date +%F-%H%M%S).tar} ;;
  esac

  echo
  log "Uninstalling Anchor+ takes away:"
  echo "  - every account, note, picture and file on this server (volumes: $volumes)"
  echo "  - its containers and images, and $ANCHOR_DIR with its settings"
  [ -n "${ports// /}" ] && echo "  - the firewall rules it added for port(s) $ports"
  [ -f "$swap_conf" ] && echo "  - the swap it added (/swapfile)"
  [ -f "$borg" ] && echo "  - borgmatic's daily backup of it ($borg); the Borg repository and its backups stay"
  echo "  Docker stays installed. The apps on phones and computers aren't touched."
  echo
  if [ "${YES:-}" = 1 ]; then
    :
  elif (: </dev/tty) 2>/dev/null; then
    interactive=1
  else
    die "No terminal to ask on. Run it again with YES=1 (it still backs up, to BACKUP_FILE or your home folder; BACKUP=no skips that)"
  fi
  if [ "$interactive" = 1 ]; then
    if [ -n "$backup_file" ]; then
      case "$(ask "Back up everything to $backup_file first? [Y/n]")" in
        n | N | no | No) backup_file= ;;
      esac
    fi
    if [ -z "$backup_file" ]; then
      warn "Without a backup, the notes can't be brought back."
    fi
    [ "$(ask "Type uninstall to remove Anchor+:")" = uninstall ] || die "Nothing was removed"
  fi

  if [ -n "$backup_file" ]; then
    log "Backing up to $backup_file..."
    docker compose up -d "$service" >/dev/null 2>&1
    wait_for_anchor "$service"
    docker compose exec -T "$service" backup >"$backup_file.partial"
    if ! tar -tf "$backup_file.partial" 2>/dev/null | grep -q 'database\.dump$'; then
      rm -f "$backup_file.partial"
      die "The backup didn't work, so nothing was removed"
    fi
    mv "$backup_file.partial" "$backup_file"
    chmod 600 "$backup_file"
    if [ -n "${SUDO_USER:-}" ]; then chown "$SUDO_USER" "$backup_file" 2>/dev/null || true; fi
  fi

  log "Removing Anchor+..."
  images=$(docker compose config --images 2>/dev/null) || true
  docker compose down --volumes --remove-orphans
  # Its images, and earlier releases' ones; one something else uses stays
  # shellcheck disable=SC2046
  for image in $images $(docker image ls -q ghcr.io/alxndrjhn/anchor); do
    docker image rm "$image" >/dev/null 2>&1 || true
  done

  for rule in $rules; do close_rule "$rule"; done
  if have firewall-cmd && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd -q --reload
  fi

  if [ -f "$swap_conf" ]; then
    if swapoff /swapfile 2>/dev/null || ! grep -q '^/swapfile ' /proc/swaps; then
      rm -f /swapfile
      sed -i '\|^/swapfile |d' /etc/fstab
    else
      warn "/swapfile is still in use, so it stays: swapoff /swapfile, then delete it and its line in /etc/fstab"
    fi
    rm -f "$swap_conf"
    sysctl -q vm.swappiness=60 >/dev/null 2>&1 || true
  fi

  if [ -f "$borg" ]; then
    rm -f "$borg"
    rm -rf /var/backups/anchor
    rmdir /etc/borgmatic.d 2>/dev/null || true
  fi

  cd /
  rm -rf "$ANCHOR_DIR"

  echo
  log "Anchor+ is uninstalled."
  echo
  if [ -n "$backup_file" ]; then
    echo "  The backup: $backup_file. Keep it safe: it holds every note and"
    echo "  sign-in. To bring it all back, install again, then in $ANCHOR_DIR:"
    echo "    docker compose exec -T anchor-plus restore < $backup_file"
    echo
  fi
  # The notes' volume from before the move to anchor-plus's own names, if
  # no container (the original Anchor's) uses it
  old_volume=$(docker volume ls -q \
    --filter label=com.docker.compose.project=anchor \
    --filter label=com.docker.compose.volume=anchor_data)
  if [ -n "$old_volume" ] && [ -z "$(docker ps -aq --filter volume="$old_volume")" ]; then
    echo "  An older copy of the notes is in the volume $old_volume. If it isn't"
    echo "  the original Anchor's: docker volume rm $old_volume"
    echo
  fi
}

main() {
  check_system
  case "${UNINSTALL:-0}" in
    0 | no | off | false | '') ;;
    *)
      uninstall
      return
      ;;
  esac
  install_docker
  add_swap
  load_settings
  write_anchor_env
  move_to_own_name
  write_compose
  open_ports
  start_anchor
  report
}

main "$@"
