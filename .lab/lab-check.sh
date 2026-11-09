#!/usr/bin/env bash
rc=0
if [ -x audit.sh ] && bash -n audit.sh && grep -q 'set -euo pipefail' audit.sh && grep -q -- '--query' audit.sh; then echo "- ✅ audit.sh is valid, strict and uses --query"; else echo "- ❌ audit.sh must exist, be executable, use set -euo pipefail and --query"; rc=1; fi
if python3 -c "import jmespath" 2>/dev/null; then
  if diff <(PATH="$PWD/tests/bin:$PATH" FAKE_AWS_VARIANT=1 ./audit.sh 2>/dev/null) tests/expected-account1.txt >/dev/null; then echo "- ✅ audit.sh produces the expected report in practice mode"; else echo "- ❌ audit.sh does not produce the expected report in practice mode (run ./verify.sh)"; rc=1; fi
else echo "- ⚠️ jmespath missing on the runner, practice-mode run skipped"; fi
[ -f whoami.py ] && python3 -m py_compile whoami.py && grep -q get_caller_identity whoami.py && echo "- ✅ whoami.py uses boto3 get_caller_identity" || { echo "- ❌ whoami.py is missing or does not call get_caller_identity"; rc=1; }
if grep -rE 'AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude=verify.sh -q 2>/dev/null; then echo "- ❌ an AWS access key id was found in the repository. Delete the key in IAM NOW and remove it from the repo"; rc=1; else echo "- ✅ no AWS access key found in the repository"; fi
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
