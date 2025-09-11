package docker_security

import rego.v1

# Deny if Dockerfile uses 'latest' tag
deny[msg] {
    some i
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    count(val) == 2
    val[1] == "latest"
    msg := sprintf("Line %v: Avoid using 'latest' tag for base image '%v'", [i, input[i].Value[0]])
}

# Warn if RUN command contains 'sudo'
warn[msg] {
    some i
    input[i].Cmd == "run"
    contains(input[i].Value[0], "sudo")
    msg := sprintf("Line %v: Avoid using 'sudo' in RUN commands: %v", [i, input[i].Value[0]])
}

# Deny if container runs as root user
deny[msg] {
    some i
    input[i].Cmd == "user"
    input[i].Value[0] == "root"
    msg := sprintf("Line %v: Running as root user is not allowed", [i])
}

# Warn about unsafe download patterns that pipe to shell
warn[msg] {
    some i
    input[i].Cmd == "run"
    regex.match(`(curl|wget).*\|.*(sh|bash)`, input[i].Value[0])
    msg := sprintf("Line %v: Avoid piping downloaded content directly to shell: %v", [i, input[i].Value[0]])
}

# Deny copying files from parent directories
deny[msg] {
    some i
    input[i].Cmd == "copy"
    contains(input[i].Value[0], "../")
    msg := sprintf("Line %v: Avoid copying files from parent directories: %v", [i, input[i].Value[0]])
}

# Warn if no HEALTHCHECK instruction is present
warn[msg] {
    count([x | input[x].Cmd == "healthcheck"]) == 0
    msg := "Consider adding a HEALTHCHECK instruction for container health monitoring"
}

# Deny if EXPOSE instruction uses privileged ports
deny[msg] {
    some i
    input[i].Cmd == "expose"
    port := to_number(input[i].Value[0])
    port < 1024
    msg := sprintf("Line %v: Avoid exposing privileged ports (< 1024): %v", [i, port])
}

# Warn about missing non-root user creation
warn[msg] {
    count([x | input[x].Cmd == "user"]) == 0
    count([x | input[x].Cmd == "run"; contains(input[x].Value[0], "adduser")]) == 0
    msg := "Consider creating and using a non-root user"
}
