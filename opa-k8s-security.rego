package kubernetes.security

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.containers[_].securityContext.runAsUser == 0
    msg = "Container should not run as root user"
}

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.containers[_].securityContext.readOnlyRootFilesystem
    msg = "Container should have read-only root filesystem"
}

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.containers[_].securityContext.privileged
    msg = "Privileged containers are not allowed"
}
