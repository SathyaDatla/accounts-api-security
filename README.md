# accounts-api security lab

A local reference implementation and decision record for the accounts-api security exercise. This repository models a containerized service on EKS, its release pipeline, workload identity and secrets, and the controls used to reduce and investigate likely attacks. It does not deploy to AWS.

## Start here

- LAB-WALKTHROUGH.md explains what each section of the exercise is asking, where the answer lives, and what the local checks prove.
- START-HERE.md has the quick Windows setup.
- docs/threat-model.md names the risks that the controls address.
- docs/decisions.md explains enforcement choices, trade-offs, residual risk, and rollout criteria.

## Run the local policy checks

Install Python 3 and Conftest, then run from the repository root:

    Set-ExecutionPolicy -Scope Process Bypass
    .\setup-lab.ps1

The script checks the safe and unsafe policy fixtures and waiver validity. If the Kyverno CLI is installed, it also runs the admission-policy tests. The optional cluster command creates a local kind cluster only; it does not deploy the example workload.

For Terraform syntax and provider validation:

    terraform -chdir=infra/terraform init -backend=false
    terraform -chdir=infra/terraform validate

No AWS credentials are needed for these local checks. Do not run terraform apply for this exercise.

## Repository layout

- .github/workflows: security gates and image release workflow
- docs: threat model, decisions, and operational procedures
- infra: Terraform, IAM role policies, and GitHub OIDC trust policy examples
- k8s and policy: workload configuration, admission rules, network policy, and fixtures
- runtime: custom Falco detection
- scripts and waivers: local policy/expiry checks and reviewed exceptions
- service and Dockerfile: small buildable stand-in used by the container examples
- Product Documents: a collected copy of the walkthrough and human-facing documents

## Scope and limitations

AWS account numbers, GitHub repository identity, network identifiers, and service endpoints are illustrative. The KYC hostname and private service names must be replaced for a real environment. OIDC trust, EKS admission, Cilium enforcement, AWS IAM access, key rotation, audit retention, and paging are described or authored as configuration examples; they were not applied to a cloud account from this lab.
