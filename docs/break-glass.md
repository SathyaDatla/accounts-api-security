# Break-glass release

Use this only when a customer-impacting outage cannot wait for the normal review path. The incident commander opens an incident record. The platform on-call engineer and service owner approve the exact finding and the smallest required exception; the exception expires within four hours.

The protected GitHub production environment still requires a reviewer. The job assumes a short-lived OIDC role, tags the session with the incident ID, and deploys an immutable image digest. The waiver records the incident link, affected control, compensating monitoring, approvers, and UTC expiry. CI blocks the next build after expiry until the normal fix is merged or a new waiver is approved.

Keep workflow approvals and commits with the incident record, and export GitHub audit events and CloudTrail to the separate security account. After the incident, remove the waiver, rotate any credential that may have been exposed, and review the actions on the next business day. Break-glass does not turn off signature checks, secret scanning, or audit logging.
