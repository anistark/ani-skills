#!/usr/bin/env bash
# Outside-in health report for the EC2 + Docker + nginx + GitHub Actions stack.
# Every check is skipped, not failed, when its tool or argument is missing. Runs on
# Linux and macOS; missing tools are reported with the install command for this system.
#
#   check-stack.sh --host api.example.com --app myapp [--path /api/health]
#                  [--instance i-... --region us-east-1] [--repo org/repo --workflow myapp.yml]
#                  [--ssh ubuntu@1.2.3.4 --key ~/.ssh/key.pem]
set -uo pipefail
HOST=""; APP=""; HPATH="/api/health"; INSTANCE=""; REGION=""; REPO=""; WORKFLOW=""; SSH=""; KEY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST=$2; shift 2;; --app) APP=$2; shift 2;; --path) HPATH=$2; shift 2;;
    --instance) INSTANCE=$2; shift 2;; --region) REGION=$2; shift 2;;
    --repo) REPO=$2; shift 2;; --workflow) WORKFLOW=$2; shift 2;;
    --ssh) SSH=$2; shift 2;; --key) KEY=$2; shift 2;;
    *) echo "unknown arg $1" >&2; exit 2;;
  esac
done
[ -n "$HOST" ] || { echo "--host is required" >&2; exit 2; }
ok() { printf '  \033[32mok\033[0m   %s\n' "$*"; }
bad() { printf '  \033[31mBAD\033[0m  %s\n' "$*"; }
skip() { printf '  \033[90mskip\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
case "$OS" in Darwin) OS=macos;; Linux) OS=linux;; *) OS="$(printf '%s' "$OS" | tr '[:upper:]' '[:lower:]')";; esac
PKG=""
for pm in brew apt-get dnf yum apk pacman zypper; do have "$pm" && { PKG=$pm; break; }; done

# install_hint <tool>: the command that installs <tool> with the detected package manager.
install_hint() {
  local pkg="$1"
  case "$1:$PKG" in
    aws:*) pkg=awscli;; timeout:brew) pkg=coreutils;;
    ssh:brew|ssh:pacman) pkg=openssh;; ssh:dnf|ssh:yum|ssh:zypper) pkg=openssh-clients;; ssh:*) pkg=openssh-client;;
    dig:apt-get) pkg=dnsutils;; dig:dnf|dig:yum|dig:zypper) pkg=bind-utils;; dig:apk|dig:pacman) pkg=bind-tools;;
  esac
  case "$PKG" in
    brew) echo "brew install $pkg";; apt-get) echo "sudo apt-get install -y $pkg";;
    dnf|yum) echo "sudo $PKG install -y $pkg";; apk) echo "sudo apk add $pkg";;
    pacman) echo "sudo pacman -S $pkg";; zypper) echo "sudo zypper install -y $pkg";;
    *) echo "install $pkg";;
  esac
}
missing() { skip "$1: $1 not found ($(install_hint "$1"))"; }

# with_timeout <seconds> <cmd...>: GNU timeout on Linux, gtimeout from coreutils on macOS,
# otherwise perl's alarm, which ships with macOS.
with_timeout() {
  local s="$1"; shift
  if have timeout; then timeout "$s" "$@"
  elif have gtimeout; then gtimeout "$s" "$@"
  elif have perl; then perl -e 'alarm shift; exec @ARGV' "$s" "$@"
  else "$@"; fi
}

# resolve <host>: first address, IPv4 preferred. getent is Linux only; macOS has dscacheutil.
resolve() {
  if have getent; then { getent ahostsv4 "$1" 2>/dev/null; getent hosts "$1"; } | awk '{print $1; exit}'
  elif have dscacheutil; then dscacheutil -q host -a name "$1" | awk '/^ip_address:/{v4=$2} /^ipv6_address:/{v6=$2} END{print (v4 ? v4 : v6)}'
  elif have dig; then dig +short "$1" | grep -E '^[0-9a-fA-F:.]+$' | head -1
  elif have python3; then python3 -c 'import socket,sys; print(socket.gethostbyname(sys.argv[1]))' "$1" 2>/dev/null
  fi
}

echo "System"
ok "$OS, package manager ${PKG:-none found}"
for t in curl openssl gh aws ssh; do have "$t" || missing "$t"; done

echo "Auth"
AWS_OK=1
if [ -n "$REPO" ] && have gh; then
  if gh auth status >/dev/null 2>&1; then
    P="$(gh api "repos/$REPO" --jq '.permissions | if .admin then "admin" elif .push then "write" elif .pull then "read" else "none" end' 2>/dev/null)"
    case "$P" in admin|write) ok "gh logged in, $P on $REPO";; read) ok "gh logged in, read only on $REPO (reruns need write)";; *) bad "gh cannot see $REPO (wrong account or no access)";; esac
  else bad "gh not logged in (gh auth login)"; fi
elif [ -z "$REPO" ]; then skip "gh: no --repo"; else skip "gh: not installed"; fi
if [ -n "$INSTANCE" ] && have aws; then
  ID="$(aws sts get-caller-identity ${REGION:+--region "$REGION"} --query '[Account,Arn]' --output text 2>&1)"
  case "$ID" in *expired*|*Expired*|*SSO*|*"Unable to locate credentials"*|*"could not be found"*) AWS_OK=0; bad "aws not logged in (aws login, aws sso login, or aws configure)";; [0-9]*) ok "aws account ${ID%%[[:space:]]*}, ${ID##*[[:space:]]}";; *) bad "aws: $ID";; esac
elif [ -z "$INSTANCE" ]; then skip "aws: no --instance"; else skip "aws: not installed"; fi

echo "DNS"
IP="$(resolve "$HOST")"
[ -n "$IP" ] && ok "$HOST -> $IP" || bad "$HOST does not resolve"

echo "HTTP"
C="$(curl -s -m 8 -o /dev/null -w '%{http_code} %{redirect_url}' "http://$HOST$HPATH")"
case "$C" in 301*|308*) ok "http redirects to https";; 200*) ok "http 200 (no https redirect yet)";; 404*) bad "http 404: nginx site probably not enabled";; 502*) bad "http 502: nginx up, backend down";; 000*) bad "http: no connection";; *) bad "http $C";; esac
C="$(curl -s -m 8 -o /dev/null -w '%{http_code}' "https://$HOST$HPATH")"
case "$C" in 200) ok "https 200";; 000) bad "https: connection failed (no certificate?)";; *) bad "https $C";; esac
if have openssl; then
  # s_client can sit on an open connection with some servers; cap it.
  EXP="$(with_timeout 10 openssl s_client -connect "$HOST:443" -servername "$HOST" </dev/null 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)"
  [ -n "$EXP" ] && ok "certificate expires $EXP" || skip "certificate: could not read"
else missing openssl; fi

echo "Pipeline"
if [ -z "$REPO" ]; then skip "pipeline: pass --repo org/repo"
elif ! have gh; then missing gh
else
  R="$(gh run list ${WORKFLOW:+--workflow "$WORKFLOW"} -R "$REPO" --limit 1 --json conclusion,headBranch,createdAt,databaseId --jq '.[0] | "\(.conclusion) \(.headBranch) \(.createdAt) run \(.databaseId)"' 2>/dev/null)"
  case "$R" in success*) ok "$R";; "") skip "no runs found";; *) bad "$R";; esac
fi

echo "SSM"
if [ -z "$INSTANCE" ]; then skip "ssm: pass --instance i-..."
elif ! have aws; then missing aws
elif [ "$AWS_OK" = 0 ]; then skip "ssm: aws not logged in"
else
  S="$(aws ssm describe-instance-information ${REGION:+--region "$REGION"} --filters "Key=InstanceIds,Values=$INSTANCE" --query 'InstanceInformationList[0].PingStatus' --output text 2>&1)"
  case "$S" in Online) ok "instance $INSTANCE Online";; None) bad "instance not registered with SSM";; *expired*|*Expired*) skip "aws session expired, see Auth above";; *) bad "$S";; esac
fi

echo "Box"
if [ -z "$SSH" ]; then skip "box: pass --ssh user@host [--key]"
elif ! have ssh; then missing ssh
else
  OUT="$(ssh ${KEY:+-i "$KEY"} -o BatchMode=yes -o ConnectTimeout=8 "$SSH" "cat /opt/${APP:-app}/.env 2>/dev/null; sudo docker ps --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null; df -h / | tail -1 | awk '{print \"disk \" \$5 \" used\"}'" 2>&1)"
  [ $? -eq 0 ] && printf '%s\n' "$OUT" | sed 's/^/  /' || bad "ssh: $OUT"
fi
