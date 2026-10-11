# What the logs keep and remove

The service logging wrapper should redact data before it serializes an event. It removes authorization and cookie headers, tokens, passwords and connection strings, names, email, phone, IBAN/account numbers, card PAN/CVV, KYC payloads, and request or response bodies.

Logs use an allowlist: request ID, route template, status, latency bucket, service version, and a pseudonymous actor ID. Do not record arbitrary headers, query strings, exception locals, or bodies. Apply the same rule to ingress logs; restrict access to ALB logs and retain them centrally.

This still reveals timing, route, status, response size, correlation, and a stable pseudonymous actor. A new field, exception message, trace, heap dump, or provider-side log can bypass this layer. Test with synthetic PII and sample production logs. The scenario only includes last-four card data; do not store full PAN or CVV, and remove last-four from logs too.
