# Accounts API Security Lab

A local security lab for a containerized accounts service on Kubernetes. It brings together threat modeling, CI security gates, workload hardening, AWS identity and secrets examples, and operational guidance.

> **Scope:** This repository is an illustrative reference implementation. It does not deploy to AWS or prove that the example controls are active in a cluster.

## Get started

The quickest path is PowerShell on Windows. Install **Python 3** and **Conftest**, open PowerShell in the repository root, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup-lab.ps1
```

The script runs the good and bad policy fixtures and checks the waiver register for required fields and expiry. If the Kyverno CLI is installed, it also runs the admission-policy tests. The execution-policy setting applies only to the current PowerShell session.

### Optional checks

**Terraform validation** checks the example infrastructure without applying it. Terraform downloads the provider during `init`; AWS credentials are not required.

```powershell
terraform -chdir=infra/terraform init -backend=false -input=false
terraform -chdir=infra/terraform validate
```

**Kyverno tests** can be run directly from the repository root:

```powershell
kyverno test k8s/kyverno/kyverno-test.yaml
```

**Local kind cluster** creation is optional and requires Docker Desktop, kind, and kubectl:

```powershell
.\setup-lab.ps1 -CreateKindCluster
```

This creates a cluster and checks connectivity; it does not install Kyverno or deploy the example workload. Remove it when finished:

```powershell
kind delete cluster --name accounts-api-lab
```

The sample uses AWS Secrets Manager and Cilium-specific egress policy, so applying it to plain kind would not demonstrate those controls.

## What’s in the lab

| Area | What to explore |
| --- | --- |
| Threat model and decisions | [Threat model](docs/threat-model.md), [security decisions](docs/decisions.md), and [detailed walkthrough](LAB-WALKTHROUGH.md) |
| CI and release integrity | [Security gates](.github/workflows/security-gates.yml), [release workflow](.github/workflows/release.yml), and [tooling rationale](docs/tooling.md) |
| Cloud and workload controls | `infra/`, `k8s/`, and `policy/` contain Terraform, IAM, Kubernetes, and Rego examples |
| Runtime and operations | `runtime/` and `docs/` cover detection, remediation, rotation, logging, encryption, and break-glass procedures |
| Waivers | `waivers/waivers.json` is the exception register; `scripts/check_waivers.py` checks structure, duration, and expiry |
| Container example | `service/` and `Dockerfile` contain a minimal health-only Go service for the image examples |

For a short orientation, see [START-HERE.md](START-HERE.md). For the full exercise map and the limits of each check, see [LAB-WALKTHROUGH.md](LAB-WALKTHROUGH.md).

## CI checks

The GitHub Actions security workflow runs secret-history scanning, static analysis, filesystem vulnerability scanning, Terraform validation, Checkov, and the policy and waiver checks. The release workflow is an example of building an image, publishing an SBOM attestation, scanning, and signing the image.

Those workflows describe intended automation. Repository identity, AWS account details, environment protection, and other organization settings are illustrative and must be reviewed before adapting them to a real release process.

## Important limits

- The Go service is a health-only stand-in; it is not a production accounts API.
- AWS account numbers, repository identity, network identifiers, and service endpoints are examples. Replace them before real use.
- OIDC trust, EKS admission, Cilium enforcement, IAM access, key rotation, audit retention, and paging are documented or authored as configuration examples. They have not been applied to a cloud account or verified in a live cluster.
- Do not run `terraform apply` for this exercise. Local checks do not need AWS credentials.
