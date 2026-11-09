#!/usr/bin/env bash
# Proves the AWS resources of this lab are gone. Run with: ./teardown-check.sh
# Needs the AWS CLI with your normal ADMIN credentials (or run it in AWS CloudShell).
set -uo pipefail
command -v aws >/dev/null || { echo "The AWS CLI is not installed. Run this in AWS CloudShell (the >_ icon in the console)." >&2; exit 1; }
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials. Use your admin profile, or AWS CloudShell." >&2; exit 1; }
echo "Checking account $ACCOUNT"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user()   { ! aws iam get-user --user-name "$1" >/dev/null 2>&1; }
no_group()  { ! aws iam get-group --group-name "$1" >/dev/null 2>&1; }
no_policy() { [ -z "$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$1'].PolicyName" --output text)" ]; }
no_buckets_with_prefix() { [ -z "$(aws s3api list-buckets --query "Buckets[?starts_with(Name, \`$1\`)].Name" --output text)" ]; }
no_budget() { ! aws budgets describe-budget --account-id "$ACCOUNT" --budget-name "$1" >/dev/null 2>&1; }

check "IAM user cli-admin is deleted, or has no access keys" bash -c "! aws iam get-user --user-name cli-admin >/dev/null 2>&1 || [ -z \"\$(aws iam list-access-keys --user-name cli-admin --query 'AccessKeyMetadata[].AccessKeyId' --output text)\" ]"
check "the profile 'clipstr' no longer works (its key was deleted)" bash -c "! aws sts get-caller-identity --profile clipstr >/dev/null 2>&1"
check "the profile 'clipstr' is removed from ~/.aws/credentials" bash -c "! grep -qs '^\[clipstr\]' ~/.aws/credentials"
check "the profile 'clipstr' is removed from ~/.aws/config" bash -c "! grep -qs '^\[profile clipstr\]' ~/.aws/config"
check "no S3 bucket named clipstr-audit-test-* is left" no_buckets_with_prefix clipstr-audit-test-
check "no access key id is exported in this shell" bash -c "[ -z \"\${AWS_ACCESS_KEY_ID:-}\" ] || [ \"\$AWS_ACCESS_KEY_ID\" = \"\$(aws configure get aws_access_key_id 2>/dev/null)\" ]"

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) in account $ACCOUNT"; else echo "NOT CLEAN: $failn leftover(s). Delete them (console or CLI) and run this again."; fi
exit "$failn"
