# Decisions and trade-offs

## The decisions I would defend

**Publish once and deploy by digest.** The release job assumes an ECR role with GitHub OIDC, tags the image with the commit SHA, creates an SPDX SBOM, and attaches it to the image as a Cosign attestation. It signs the image keylessly and verifies both before release completes. ECR tag immutability prevents a tag from being replaced. The signature ties these bytes to a workflow identity; it does not say the code is safe or that a human reviewed every line.

**Enforce escape-path controls, but stage the rollout.** For accounts-api, non-root execution, no host paths or host namespaces, no privilege escalation, and digest-pinned images are baseline requirements. The Kyverno policy starts in Audit mode. I would move it to Enforce for this namespace after two clean weeks, owner review, an exception inventory, and a rollback rehearsal. This avoids surprising other teams on a shared cluster.

**Use Cilium for name-based egress.** Kubernetes NetworkPolicy cannot match a DNS name. Maintaining provider IP ranges by hand is likely to break KYC calls. Cilium allows DNS for the named provider and TLS to that provider, along with the private database and stream endpoints this service needs. This still permits misuse of an allowed host and does not stop DNS tunnelling through allowed DNS.

## What blocks a merge

| Check | Day-one behavior | Evidence to change the posture |
|---|---|---|
| Full-history Gitleaks; expired waiver; critical/high Trivy finding | Block | Already blocking; test with synthetic findings and confirm the credential-revocation runbook. |
| Semgrep CI findings | Block high-confidence findings | Review false positives for a month; keep the rate below 5% and use narrow, owned suppressions. |
| Checkov | Block every failed check in this Terraform directory | Review the first findings with the platform owner; use an expiring waiver for accepted exceptions. |
| Medium/low dependency findings | Warn and assign an owner and due date | Promote only after a month of triage and a false-positive review. |
| Kyverno in the shared cluster | Audit first; later enforce for accounts-api | Two clean weeks, workload-owner signoff, exception inventory, and rollback practice. |

Trivy is used for both dependency and image scanning; it does not provide reachability analysis. Semgrep uses its CI ruleset. Gitleaks checks the complete checkout history. Checkov provides broad Terraform checks, while the Rego policies express the specific invariants tested here.

## Waivers and emergency releases

A waiver records the finding, reason, compensating control, owner, approver, issue, and UTC expiry. Normal waivers last at most 30 days; an incident waiver lasts at most four hours. The expiry checker fails the build if a waiver is malformed, too old, or expired. Any suppression must point back to its waiver.

For the file to count as approved, GitHub must require a verified signed commit, two reviews, CODEOWNERS approval from platform, and no self-approval or admin bypass. Those repository rules are documented in `docs/branch-protection.md`; they cannot be enforced by files in this archive alone. The emergency path and its evidence are in `docs/break-glass.md`.

## Two ways this can go wrong

**If the API has an RCE:** the attacker can use the app’s database access and read its mounted runtime secret. They should not be able to reach the node’s Docker socket, host logs, other namespaces’ secrets, broad AWS actions, or arbitrary internet hosts. We should have EKS audit, Cilium flow/DNS, Falco, CloudTrail, RDS, and ALB/WAF records in a separately retained account. We will not see every in-memory read or misuse that looks like an ordinary authorized API request.

**If a maintainer account and workflow are taken over:** the attacker can try to change the source or CI. Branch review, required checks, the protected production environment, and the OIDC subject should stop a PR or non-production ref from getting the release role. The image signature, attestation, GitHub audit history, and CloudTrail role session give us a trail. If an environment approver or organization admin is also compromised, those checks lose much of their value. We also need GitHub’s audit export configured outside this repository.

## A gap I would accept for this exercise

A slow scrape using valid customer sessions may look like normal API traffic. Closing that gap needs per-customer behavior baselines, rate analysis, and a staffed response function. That is a product and operations project, not a Falco rule.

| Control | Why an examiner cares |
|---|---|
| EKS and RDS in ap-south-1 (assumption) | Data residency |
| Validated, multi-region CloudTrail with locked retention | Audit integrity and reconstruction |
| Encrypted RDS and retained backups | Confidentiality and recovery |
| Narrow pod role and reviewed, expiring waivers | Access review |
| No full PAN/CVV storage; remove last-four from logs | Cardholder-data scope |
| Named alert owner and runbook | Breach readiness |

I did not deploy a cluster, apply Terraform, build the full business API, run DAST, or configure organization-wide GuardDuty. Before production, I would pin GitHub Actions and container base images to reviewed immutable digests. On Monday, I would canary the admission and egress policy, send the logs to the security account, and test the on-call path end to end.
