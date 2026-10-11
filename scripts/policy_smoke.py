#!/usr/bin/env python3
"""Run good fixtures and assert unsafe fixtures fail for policy findings."""
import subprocess
import sys

cases = [
    ("kubernetes", "k8s/base/deployment.yaml", False),
    ("kubernetes", "k8s/fixtures/bad-deployment.yaml", True),
    ("kubernetes", "k8s/fixtures/bad-role.yaml", True),
    ("terraform", "infra/terraform/fixtures/good-db.yaml", False),
    ("terraform", "infra/terraform/fixtures/bad-db.yaml", True),
]
failed = False
for namespace, path, expect_deny in cases:
    result = subprocess.run(
        ["conftest", "test", "--policy", "policy/rego", "--namespace", namespace, path],
        text=True, capture_output=True,
    )
    output = result.stdout + result.stderr
    denied = result.returncode != 0 and "FAIL" in output
    ok = denied if expect_deny else result.returncode == 0
    print(f"{'PASS' if ok else 'FAIL'} expected {'deny' if expect_deny else 'allow'}: {path}")
    if not ok:
        print(output)
        failed = True
sys.exit(1 if failed else 0)
