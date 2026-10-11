# GitHub settings this repository cannot set

For main, require two approvals, CODEOWNERS approval for workflows, infrastructure, admission policies, and waivers; dismiss stale reviews; prohibit self-approval, force-push, deletion, and unreviewed admin bypass; and require the security-gates status check. Require verified signed commits for waiver changes.

Restrict the production environment to main and require a platform reviewer. Export the organization audit log to the security account. These settings live in GitHub, not in the repository, so verify them before using the release workflow.
