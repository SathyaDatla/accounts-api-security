# Local laptop setup

This lab can run without AWS. The repo has policy fixtures and sample configurations; it does not provision cloud resources.

## Fast path (PowerShell)

1. Extract the project somewhere writable, such as a folder under your user profile.
2. Install Python 3 and Conftest. For admission tests, also install the Kyverno CLI. For an optional local Kubernetes cluster, install Docker Desktop, kind, and kubectl, then start Docker Desktop.
3. Open PowerShell in the project folder and run the following commands:

    Set-ExecutionPolicy -Scope Process Bypass
    .\setup-lab.ps1

The script runs the safe/unsafe Rego fixtures and waiver expiry check. It runs Kyverno tests if the CLI is present, and reports when they are skipped. It does not install software or contact AWS.

To also create a local kind cluster (optional), run:

    .\setup-lab.ps1 -CreateKindCluster

This only creates the cluster. It does not deploy the workload: the sample uses AWS Secrets Manager and Cilium-specific egress policy, so applying it to plain kind would give a misleading result. Remove the optional cluster when finished with: kind delete cluster --name accounts-api-lab

## Optional checks

- terraform -chdir=infra/terraform init -backend=false and terraform -chdir=infra/terraform validate validate the authored IaC. A plan needs input values and still does not apply anything.
- kyverno test k8s/kyverno/kyverno-test.yaml runs admission fixtures.
- Docker is only needed for the optional kind cluster or image build. AWS credentials are not needed for the local policy exercises.

If PowerShell blocks scripts, Set-ExecutionPolicy -Scope Process Bypass applies only to that PowerShell session.
