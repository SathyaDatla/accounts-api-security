# Runtime alert and egress

The custom Falco rule in `runtime/falco/accounts-api.yaml` fires when the accounts-api container starts a shell or common network utility. A normal Go HTTP service should not need to do that, so the event is worth a page. It will miss in-process abuse and renamed tools.

Send the alert to the central security event bus through Falcosidekick, then page the platform on-call engineer and service owner. Include rule, time, cluster, namespace, pod, container, image, process and parent, user, and node. Keep command arguments out of the alert because they can contain secrets.

The responder should:
1. Preserve pod, node, EKS audit, flow, and process evidence; record the image digest and request IDs.
2. Ask the incident commander before isolating the workload; block egress and replace pods only after evidence is preserved.
3. Revoke and rotate the database and KYC credentials, then check CloudTrail, RDS, and audit records for access.

Cilium allows the named KYC host on TLS 443, the private RDS alias on 5432, and the private stream brokers on 9094. DNS is allowed only for those names. Everything else is denied by the namespace default-deny policy. This does not stop abuse of an allowed hostname, a shared CDN address, or DNS tunnelling through an allowed name. Pin the provider identity in the application and review unusual DNS and flow volume.
