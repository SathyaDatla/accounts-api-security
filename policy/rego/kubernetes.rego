package kubernetes

import rego.v1

deny contains msg if {
  input.kind == "Deployment"
  object.get(input.spec.template.spec, "hostNetwork", false) == true
  msg := "T1/T4: hostNetwork is forbidden"
}
deny contains msg if {
  input.kind == "Deployment"
  object.get(input.spec.template.spec, "hostPID", false) == true
  msg := "T1/T4: hostPID is forbidden"
}
deny contains msg if {
  input.kind == "Deployment"
  object.get(input.spec.template.spec, "hostIPC", false) == true
  msg := "T1/T4: hostIPC is forbidden"
}
deny contains msg if {
  input.kind == "Deployment"
  some v in object.get(input.spec.template.spec, "volumes", [])
  "hostPath" in object.keys(v)
  msg := "T1/T4: hostPath volume is forbidden"
}
deny contains msg if {
  input.kind == "Deployment"
  some c in object.get(input.spec.template.spec, "containers", [])
  object.get(object.get(c, "securityContext", {}), "privileged", false) == true
  msg := "T1/T4: privileged container is forbidden"
}
deny contains msg if {
  input.kind == "Deployment"
  some c in object.get(input.spec.template.spec, "containers", [])
  object.get(object.get(c, "securityContext", {}), "allowPrivilegeEscalation", true) != false
  msg := "T1/T4: privilege escalation must be disabled"
}
deny contains msg if {
  input.kind == "Deployment"
  some c in object.get(input.spec.template.spec, "containers", [])
  object.get(object.get(c, "securityContext", {}), "runAsUser", 10001) == 0
  msg := "T1: container may not run as root"
}
deny contains msg if {
  input.kind == "Deployment"
  object.get(object.get(input.spec.template.spec, "securityContext", {}), "runAsNonRoot", false) != true
  msg := "T1: pod must require non-root"
}
deny contains msg if {
  input.kind == "Deployment"
  some c in object.get(input.spec.template.spec, "containers", [])
  object.get(object.get(c, "securityContext", {}), "readOnlyRootFilesystem", false) != true
  msg := "T1: root filesystem must be read-only"
}
deny contains msg if {
  input.kind == "Deployment"
  some c in object.get(input.spec.template.spec, "containers", [])
  not contains(object.get(c, "image", ""), "@sha256:")
  msg := "T2: image must be pinned by digest"
}
deny contains msg if {
  input.kind == "Role"
  some rule in input.rules
  rule.verbs[_] == "*"
  msg := "T4: wildcard RBAC verbs are forbidden"
}
deny contains msg if {
  input.kind == "Role"
  some rule in input.rules
  rule.resources[_] == "secrets"
  msg := "T3/T4: API service roles may not read Kubernetes secrets"
}
