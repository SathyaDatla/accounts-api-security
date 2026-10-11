# Why these tools

- **Trivy** scans dependencies and the built image in one place. Critical and high findings block. It does not do reachability analysis.
- **Semgrep** uses its CI ruleset for high-confidence static findings.
- **Gitleaks** scans the full checkout history, not just the PR diff.
- **Checkov** provides broad Terraform checks; because severity labels vary, every failed check blocks. Conftest adds the specific rules and regression fixtures for this design.

Using one scanner for dependencies and images keeps the pipeline small, but we give up SCA reachability analysis and a dedicated hosted secret-history service. We compensate with full-history scanning, threat-based triage, and reviewed expiring exceptions.
