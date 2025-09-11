package docker_security

import rego.v1

# Deny using 'latest' tag
deny contains msg if {
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    count(val) == 2
    val[1] == "latest"
    msg := sprintf("Line %v: Avoid using 'latest' tag for base image '%v'", [i, input[i].Value[0]])
}

# Warn about sudo usage
warn contains msg if {
    input[i].Cmd == "run"
    contains(input[i].Value[0], "sudo")
    msg := sprintf("Line %v: Avoid using 'sudo' in RUN commands: %v", [i, input[i].Value[0]])
}

# Deny running as root
deny contains msg if {
    input[i].Cmd == "user"
    input[i].Value[0] == "root"
    msg := sprintf("Line %v: Avoid running container as root user", [i])
}

# Warn about unsafe download patterns
warn contains msg if {
    input[i].Cmd == "run"
    regex.match(`(wget|curl).*\|.*(sh|bash)`, input[i].Value[0])
    msg := sprintf("Line %v: Avoid piping downloads directly to shell: %v", [i, input[i].Value[0]])
}

# Deny parent directory references in COPY
deny contains msg if {
    input[i].Cmd == "copy"
    contains(input[i].Value[0], "../")
    msg := sprintf("Line %v: Avoid parent directory references in COPY: %v", [i, input[i].Value[0]])
}

# Warn about missing HEALTHCHECK
warn contains msg if {
    count([x | input[x].Cmd == "healthcheck"]) == 0
    msg := "Consider adding HEALTHCHECK instruction"
}
Upd
