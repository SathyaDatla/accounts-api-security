# Accounts API security lab: detailed walkthrough

## Why this lab exists

The exercise asks you to secure the path from a code change to a running accounts service, then explain why each control is in the design. It is meant to model a regulated bank service that handles customer account data, runs in a shared Kubernetes cluster, and depends on AWS identity, secrets, storage, and audit services.

The goal is not to build a real bank API or deploy anything to AWS. The service in this repository is a small stand-in so the image and pipeline examples have something concrete to build. The goal is to show that you can identify the likely attack paths, choose a few controls that stop those paths, test the controls locally, describe the limits, and give operators a way to handle exceptions.

In the original assignment, Part 1 has six technical sections and Part 2 is the decisions document. This guide groups the submission into eight reviewer-facing parts: repository setup, threat model, build integrity, pipeline gates and waivers, remediation and preventive policy, admission/runtime/egress, secrets/data protection, and decisions. The repository and README tie those parts together.

## Start here

1. Extract the archive into a folder where you can edit files.
2. Read this guide once, then read docs/threat-model.md. Keep the five named threats in mind as you inspect the code.
3. Install Python 3 and Conftest for the local policy tests. Kyverno CLI is needed for the admission fixture tests. Docker Desktop, kind, and kubectl are only needed for the optional local cluster.
4. From PowerShell at the project root, run the following:

    Set-ExecutionPolicy -Scope Process Bypass
    .\setup-lab.ps1

The launcher checks the safe and unsafe fixtures, checks that waivers are valid and not expired, and runs the Kyverno tests if its CLI is installed. A bad fixture is supposed to be denied by policy; the smoke test itself should report that as a passing expectation. The script does not provision AWS resources or deploy the workload.

If you need to run the checks individually, the commands are listed in LAB-WALKTHROUGH.md's quick setup section and README.md. The source scripts are in scripts/.

## Part 1 — repository and reviewer entry point

The repository should make it easy for a reviewer to answer three questions: what can I run, what is intentionally only an example, and where is the reasoning? README.md is the entry point. START-HERE.md is the short Windows setup. This guide adds the detailed map. .github/workflows contains the CI examples; docs contains the threat model, decisions, incident procedures, and operational notes; infra, k8s, policy, runtime, service, and waivers contain the build artifacts.

The main exercise deliverable is a coherent repository, not a collection of pasted YAML files. Keep paths and filenames readable. When adapting this lab, preserve the trace from each policy or scanner gate to a named threat. If you add a control with no threat connection, explain why it belongs anyway.

## Part 2 — Section 1: threat model

### What you are being asked to do

Name the important trust boundaries and rank five likely threats for this particular service. For each, identify the attacker's starting point, what they could reach, and which control in the submission blocks or limits the path. Also name one threat you think is overemphasized here and explain why.

### Where to look

Read docs/threat-model.md. Its Mermaid drawing follows customer traffic through CloudFront, ALB, EKS, and the data services. It also shows the separate release path from GitHub Actions to ECR and EKS, and the pod's identity path to Secrets Manager and KMS.

The ranked risks are: code execution in the API; a compromised maintainer changing the release workflow; secret or customer-data exposure; pivoting from another tenant in the shared cluster; and database exposure or incomplete audit evidence. The overemphasized risk is treating every low-severity dependency alert as an immediate release blocker.

### What the reasoning should teach

A useful threat model is a budget decision. It gives the later sections a reason to exist. For example, host namespace restrictions answer the shared-cluster pivot risk; OIDC and signing address a modified release path; secret redaction and rotation reduce data exposure; the Terraform fixes reduce database exposure and improve evidence. Do not add a control simply because a scanner can find it.

## Part 3 — Section 2: build and release integrity

### What you are being asked to do

Show how source becomes a container image that can be identified and verified. The exercise asks for an SBOM attached as an attestation, an image signature and a verification step, a GitHub-to-AWS OIDC trust policy, and immutable image tags.

### Where to look

- .github/workflows/release.yml builds and publishes the image, creates an SBOM, signs the image, attaches the attestation, and verifies the signature.
- infra/iam/github-oidc-trust.json shows the intended GitHub OIDC trust relationship and narrows the subject to the repository/environment.
- infra/terraform/main.tf sets the ECR repository to immutable tags and enables image scanning.
- docs/tooling.md and docs/decisions.md explain the pipeline choices.

### How to read the claim

A signature says that the identified workflow identity signed a specific image digest. The SBOM attestation says what inventory was associated with that build. Neither proves the code is safe, that a reviewer understood the change, that the runtime is uncompromised, or that the workflow identity itself was uncompromised. A digest is the identity of the image bytes; a mutable tag is only a label. ECR immutability prevents the same tag from being silently replaced.

The trust policy is authored, not installed in an AWS account. In a real deployment, substitute the actual GitHub organization, repository, and protected environment, then validate that a branch or pull request subject cannot assume the production role.

## Part 4 — Section 3: pipeline gates and waiver path

### What you are being asked to do

Run dependency, source, secret, and IaC checks in CI. Define which findings block a merge, explain why, scan the complete Git history for secrets, and implement an exception path that expires. Also document a production emergency route that leaves an audit record.

### Where to look

- .github/workflows/security-gates.yml defines Trivy, Semgrep, Gitleaks, Checkov, Conftest, and Terraform validation.
- waivers/waivers.json is the signed-reviewable in-repository exception register; it starts empty.
- scripts/check_waivers.py rejects malformed or expired entries.
- docs/break-glass.md describes the emergency path.
- docs/tooling.md records scanner choices and expected tuning.

Gitleaks must receive the full checkout history, not just the current commit. In GitHub Actions this means fetching full history with an unshallow checkout before scanning. Check the workflow configuration for this behavior.

### How to read the threshold and waiver design

The pipeline blocks critical and high dependency findings, high-confidence static findings, secrets found in history, failed required IaC checks, and invalid or expired waivers. Lower severity findings can be warnings with an owner and due date. This concentrates attention on issues with plausible impact while leaving room to tune false positives.

A waiver needs a finding identifier, reason, compensating control, owner, approver, tracking issue, and UTC expiry. It needs code-owner review and a verified signed change in the real GitHub repository; a JSON file alone cannot enforce those organization settings. Expiry is not a reminder: the check should fail once the date passes. Break-glass use should be narrow, time-limited, linked to an incident, and followed by retrospective review.

When adapting the workflow, confirm action versions, permissions, protected environment rules, and repository secret handling. Those rely on GitHub organization configuration and cannot be proven by reading the YAML alone.

## Part 5 — Section 4: review defects and prevent recurrence

This section supplies insecure production examples and asks you to repair them, rank them by practical exploitability, and encode structural checks so the same mistake fails policy tests next time. The prevention rules matter more than a list of scanner findings.

### 4a. Kubernetes workload and RBAC

Inspect k8s/base/deployment.yaml and k8s/base/rbac.yaml for the corrected versions. The original example used host networking, root, a floating latest tag, a Docker socket and host log mounts, and a Role that could freely read and modify Secrets, Pods, and ConfigMaps. Those settings can turn an API compromise into node or neighboring-workload compromise.

The repaired workload runs as a non-root UID, drops capabilities, disables privilege escalation, uses a pinned image reference, and removes host access. Its Kubernetes service account should not have API permissions unless the service needs them. The RBAC is narrowed to no permissions for this application path.

The rules are in policy/rego/kubernetes.rego and k8s/kyverno/policies.yaml. The intentionally bad fixtures are in k8s/fixtures/. scripts/policy_smoke.py expects Conftest to reject them. Kyverno's positive and negative examples are in k8s/kyverno/kyverno-test.yaml.

### 4b. Terraform

Read infra/terraform/main.tf and policy/rego/terraform.rego. The repaired database is private, encrypted with KMS, backed up, protected from accidental deletion, and reachable only from the application's security group. CloudTrail is multi-region, validates log files, includes global events, and writes to a bucket configured for encryption and retention.

The bad and good policy fixtures are under infra/terraform/fixtures/. They are small policy inputs designed to prove the rule behavior. They do not create AWS resources. The Terraform itself is an example configuration; its input identifiers and AWS account values need real environment-specific values before a production plan.

### 4c. Pod identity IAM policy

Read infra/iam/accounts-api-role-policy.json and infra/iam/DENIES.md. The original policy had a broad NotAction allow and missing resource scoping, which effectively granted far more than the service needs. The replacement should name the exact secret and KMS key resources and only the read/decrypt actions the service requires. Be able to say exactly which broad permissions the new policy denies.

A useful review question is: if the pod is fully compromised, which AWS API calls can it make with its role, and what data can those calls reach? Policy names do not establish least privilege by themselves; resource ARNs and conditions do the important work.

## Part 6 — Section 5: admission, runtime detection, and egress

### Admission policy

The Kyverno baseline in k8s/kyverno/policies.yaml makes unsafe workload settings visible or rejectable: root execution, host access, privilege escalation, and image identity should not be accepted silently. The test fixtures show bad manifests being rejected.

The document design starts shared-cluster rollout in Audit, then promotes the accounts-api scope to Enforce after owners have reviewed the reports, exceptions are understood, and rollback is rehearsed. That distinction matters: a policy can be technically correct but operationally disruptive across a cluster owned by many teams. The policy's mode and promotion criteria are in k8s/kyverno/README.md and docs/decisions.md.

Run the policy tests with:

    Push-Location k8s
    kyverno test kyverno/kyverno-test.yaml
    Pop-Location

### Runtime detection

runtime/falco/accounts-api.yaml contains a workload-specific rule for suspicious shell execution in the accounts-api container. docs/runtime.md explains the alert payload, destination, on-call owner, and the first responder steps. The point is to make a detection actionable: the alert needs enough context to identify the pod and container, a known destination, a person who gets paged, and a short response procedure.

A runtime rule is not a prevention control and cannot see every abuse of a valid database session. A good write-up names that gap.

### Egress

k8s/base/network-policy.yaml demonstrates the intended Cilium name-based egress rule: allow the KYC provider and required private dependencies, then deny other outbound traffic. Plain Kubernetes NetworkPolicy does not express a DNS hostname allowlist, which is why this example uses Cilium. It still cannot stop misuse of the allowed KYC endpoint or all covert channels over a permitted DNS/TLS path. The policy needs the actual vendor hostname, cluster DNS, database, and stream destinations before rollout.

Do not apply this Cilium policy to plain kind and assume it is enforced. A standard kind cluster does not include the Cilium dataplane.

## Part 7 — Section 6: secrets and data protection

### Secret delivery and rotation

k8s/base/secret-store.yaml shows an External Secrets integration with AWS Secrets Manager. The manifest names the secret reference and identity path; it does not contain a database password. In production, EKS workload identity (IRSA or EKS Pod Identity) should authorize this specific service account to retrieve one secret and decrypt it with the intended KMS key.

docs/rotation.md describes scheduled and emergency rotation, plus target times for each credential. Read it with the deployment: rotation must account for the running process, database connection pool, secret refresh interval, and failed rollouts. During an incident, the goal is to rotate quickly, revoke the old credential, restart or refresh the workload, and verify old sessions are no longer useful. A rotation plan that changes Secrets Manager but leaves a live process holding the old value is incomplete.

### Logging and encryption

docs/log-redaction.md names fields that should be removed before request data is serialized to logs, the layer responsible for redaction, and what can still leak through metadata or error messages. Logging request context is not permission to log customer records. Test logs with synthetic examples before deployment; never use real customer data in fixtures.

docs/encryption.md explains what is encrypted, which key custody model is intended, and what encryption does and does not protect against. Encryption at rest protects stored data and snapshots from some storage-layer access; it does not prevent an authorized or compromised application process from reading plaintext while serving requests.

## Part 8 — Part 2: decisions, trade-offs, and submission

docs/decisions.md is the short argument for the controls and the costs they carry. It covers the choices you would defend hardest, what blocks on day one and what warns, rollout evidence for moving audit to enforce, two attacker scenarios, an important detection gap, regulatory framing, and what was cut.

Read this document after the artifacts. It is meant to make the implementation legible, not to replace it. Be ready to explain why a particular control is enforced immediately, why another is staged, and what compensating measure covers the gap.

The top-level README.md gives the reviewer quick test instructions. The archive is the repository handoff. Before using this in a real GitHub repository, add branch protection and code-owner rules, use actual repository and AWS identifiers, review pinned action versions, and confirm your security findings and waivers with the owners.

## Optional local cluster and IaC checks

The setup launcher can create a local kind cluster if Docker Desktop, kind, and kubectl are installed:

    .\setup-lab.ps1 -CreateKindCluster

This only creates the cluster and confirms connectivity. It does not install Kyverno or deploy the service. Delete it afterward with:

    kind delete cluster --name accounts-api-lab

Terraform can be checked without applying:

    terraform -chdir=infra/terraform init -backend=false
    terraform -chdir=infra/terraform validate

The init step fetches the AWS provider. No AWS credentials are needed for init or validate. Do not run terraform apply for this exercise.

## What success looks like

A successful local walkthrough means the policy tests allow the good fixtures and deny the bad ones, the waiver checker accepts the empty valid waiver file, Kyverno tests pass when the Kyverno CLI is present, and Terraform validates if you choose to run it. A successful review means more than green commands: you can connect each control to a threat, name the operational cost, show how exceptions expire, and clearly state what remains untested.

The exercise intentionally stops before real deployment. The OIDC trust relationship, EKS admission mode, IAM access, Cilium enforcement, secrets rotation, log routing, CloudTrail retention, and incident paging all require configuration and evidence in the real environment. The repository documents those boundaries instead of claiming they were exercised locally.
