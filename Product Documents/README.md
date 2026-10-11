# accounts-api security exercise

This is a local reference submission for the accounts-api scenario. It contains the build and policy examples, plus the reasoning behind them. Nothing here was deployed to AWS.

## Organized folders

The package includes a self-contained runnable copy in [Labs](Labs/) and collected reviewer-facing documents in [Product Documents](<Product Documents/>). See [FOLDER-GUIDE.md](FOLDER-GUIDE.md) for the map.

## Set up locally

See [LAB-WALKTHROUGH.md](LAB-WALKTHROUGH.md) for the full local run-through, or [START-HERE.md](START-HERE.md) for the quick setup. The setup-lab.ps1 launcher runs local policy and waiver checks without using AWS.

## Run the policy checks

Install Python 3 and Conftest, then run these from the repository root:

- `python scripts/policy_smoke.py` checks that the safe fixtures pass and the unsafe workload, Role, and database fixtures are rejected.
- `python scripts/check_waivers.py` checks the waiver file for missing fields, invalid dates, and expired exceptions.
- From `k8s/`, `kyverno test kyverno/kyverno-test.yaml` runs the admission-policy cases.

For a Terraform plan, provide the private subnet, security group, KMS key, and CloudTrail bucket inputs, then run `terraform init -backend=false`, `terraform plan -out=tfplan`, and `terraform show -json tfplan > tfplan.json`. Check that plan with:

`conftest test --policy policy/rego --namespace terraform tfplan.json`

The GitHub workflows also run Trivy, Semgrep, Gitleaks, Checkov, Conftest, and Terraform validation. I could not run those tools in this restricted Windows environment because process execution was blocked.

## What is included

- `docs/threat-model.md` and `docs/decisions.md`: risks, controls, trade-offs, and rollout
- `.github/workflows/`: security gates and image release
- `infra/`: AWS IAM and Terraform examples
- `k8s/` and `policy/rego/`: workload, secrets, network, and admission controls
- `docs/`: break-glass, rotation, redaction, runtime response, and repository settings

The AWS account, GitHub organization/repository, VPC inputs, KMS key, and provider host are examples. Replace them before adapting this design. The KYC host is shown as `kyc.example.com`; the private stream and database DNS names are also placeholders.
