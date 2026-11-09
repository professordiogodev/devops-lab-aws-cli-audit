#!/usr/bin/env bash
# Tests audit.sh against a practice AWS (no real account needed). Run with: ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"; ROOT=$(pwd)
python3 -c "import jmespath" 2>/dev/null || { echo "Practice mode needs jmespath:  sudo apt install python3-jmespath   (or: pip install jmespath)"; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
practice() { PATH="$ROOT/tests/bin:$PATH" FAKE_AWS_VARIANT="$1" "${@:2}"; }

read -r -d '' EXPECT1 <<'X'
ACCOUNT 111122223333
CALLER arn:aws:iam::111122223333:user/cli-admin
REGIONS_ENABLED 6
RUNNING_INSTANCES eu-west-1 2
RUNNING_INSTANCES us-east-1 1
BUCKET clipstr-assets BLOCK_PUBLIC_ACCESS no
BUCKET clipstr-finance BLOCK_PUBLIC_ACCESS yes
BUCKET clipstr-uploads BLOCK_PUBLIC_ACCESS yes
BUCKET old-demo-site BLOCK_PUBLIC_ACCESS no
USERS_WITHOUT_MFA priya,sam-intern
X
read -r -d '' EXPECT2 <<'X'
ACCOUNT 999988887777
CALLER arn:aws:iam::999988887777:user/cli-admin
REGIONS_ENABLED 3
RUNNING_INSTANCES eu-west-1 5
BUCKET acme-data BLOCK_PUBLIC_ACCESS yes
BUCKET acme-logs BLOCK_PUBLIC_ACCESS yes
USERS_WITHOUT_MFA none
X

echo "== Your scripts =="
check "audit.sh exists, is executable and valid bash"          bash -c "[ -x audit.sh ] && bash -n audit.sh"
check "audit.sh uses strict mode (set -euo pipefail)"          grep -q 'set -euo pipefail' audit.sh
check "audit.sh uses --query (JMESPath), not just grep and sed" grep -q -- '--query' audit.sh
check "whoami.py compiles and uses boto3 to call get_caller_identity" bash -c "python3 -m py_compile whoami.py && grep -q boto3 whoami.py && grep -q get_caller_identity whoami.py"
check "no AWS keys are written in the repository"              bash -c "! grep -rE 'AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude=verify.sh"

echo "== audit.sh against practice AWS =="
got1=$(practice 1 ./audit.sh 2>&1); rc1=$?
check "account 1: exit code 0"                                  test "$rc1" = 0
check "account 1: the report is exactly right"                  test "$got1" = "$EXPECT1"
got2=$(practice 2 ./audit.sh 2>&1); rc2=$?
check "account 2 (different data): the report is exactly right" test "$rc2" = 0 -a "$got2" = "$EXPECT2"
check "a bucket without public-access-block configuration is reported as 'no', not a crash" bash -c "grep -q 'clipstr-assets BLOCK_PUBLIC_ACCESS no' <<< \"\$1\"" _ "$got1"
check "a profile argument is accepted (./audit.sh myprofile)"    bash -c "PATH='$ROOT/tests/bin:'\$PATH FAKE_AWS_VARIANT=1 ./audit.sh myprofile >/dev/null 2>&1"

if [ "$failn" -ne 0 ]; then
  echo; echo "--- what your script printed for account 1 (expected is in tests/expected-account1.txt) ---"; echo "$got1" | head -15
fi
echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
