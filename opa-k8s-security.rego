package main

# Fail if a Service is not NodePort (same logic you had)
deny contains msg if {
  input.kind == "Service"
  not input.spec.type == "NodePort"
  msg := "Service type should be NodePort"
}

# Fail if any Deployment container does not set runAsNonRoot=true
deny contains msg if {
  input.kind == "Deployment"
  some i
  containers := input.spec.template.spec.containers
  # if securityContext/runAsNonRoot is missing or not true -> fail
  not containers[i].securityContext.runAsNonRoot == true
  cname := containers[i].name
  msg := sprintf("Container %q must not run as root: set securityContext.runAsNonRoot=true", [cname])
}
