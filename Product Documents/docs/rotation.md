# Credential rotation

Secrets Manager is the source of truth. It encrypts values with a customer-managed KMS key. External Secrets Operator uses a narrowly scoped IRSA role to create the namespaced Kubernetes Secret; the repository contains only secret names and keys, never credentials. RDS manages its master password, while the application uses a separate database login.

Rotate the application database login every 30 days and the KYC key every 90 days, or sooner if the provider requires it. For routine rotation, create the replacement, publish it as the current secret version, refresh the mounted Secret, roll the pods, confirm new connections, then revoke the old credential. The target is under ten minutes from publication to all pods using the new value.

For an incident, revoke the exposed credential immediately; do not wait for the schedule. Create and publish a replacement, force the refresh and rollout, confirm the old credential is no longer being used, and then investigate its use. The targets are five minutes to revoke and fifteen minutes to move every consumer to the replacement from incident declaration. For suspected AWS role abuse, remove or narrow the IRSA role and terminate the affected pods as well. Rotation cannot undo a credential that an attacker already copied.
