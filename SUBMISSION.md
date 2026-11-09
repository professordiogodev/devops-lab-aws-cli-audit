# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `audit.sh` and `whoami.py`: your two scripts, committed to the repo

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste the output of `aws sts get-caller-identity` for your configured profile. Which credentials is the CLI using and in which order does it look for them (flags, environment, profile, instance role)?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the report `./audit.sh` produced against your real account. Did it find anything that surprised you?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. `aws s3api get-public-access-block` fails with an error for a bucket that has no configuration. What happened to your script when it hit that bucket, and what did you do about it? Why is a missing configuration a finding?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Show one `--query` expression you wrote and explain it piece by piece. When would you use `--output text` instead of JSON, and what is the risk?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Why should long-lived access keys on a laptop worry a security team? Name two alternatives the CLI supports and when each fits.

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->
