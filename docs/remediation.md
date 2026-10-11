# Production review: what I would fix first

1. **Host access and root execution.** The workload used host networking, UID 0, the Docker socket, and the host log directory. With API code execution, that is a plausible route from one service to the node and neighboring workloads. The replacement has no host mounts or host namespaces, runs non-root, drops capabilities, and uses a read-only root filesystem.
2. **Wildcard Kubernetes Role.** A stolen service-account token could read namespace secrets and alter pods or configmaps. The API does not need Kubernetes API access, so the replacement has no Role or RoleBinding and disables token mounting.
3. **Public, unencrypted database.** A world-open PostgreSQL port and no backup window invite direct attacks and make recovery harder. The Terraform uses private subnets, encryption, app-security-group ingress, backups, deletion protection, and a final snapshot.
4. **Incomplete CloudTrail.** A single-region trail without log validation or global events leaves gaps in the evidence. The replacement enables those settings and stores logs in a versioned, encrypted bucket with one-year compliance retention.
5. **Broad IAM policy.** The supplied NotAction policy has an empty Resource and is not valid as written. If the intended Resource was “*”, it effectively allows almost everything other than deleting IAM users and roles. The replacement permits only reads of the named runtime secret and decryption through Secrets Manager for that secret.

The database master password is managed by RDS. The application receives a separate, least-privilege login through Secrets Manager. The Terraform is a module fragment: replace the example account, subnet, KMS, and security-group values before validating a real plan.
