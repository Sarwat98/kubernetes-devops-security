package docker.security

deny[msg] {
    input[i].Cmd == "from"
    val := input[i].Value
    contains(val[i], "latest")
    msg = "Use specific image tags instead of 'latest'"
}

deny[msg] {
    input[i].Cmd == "user"
    val := input[i].Value
    val[0] == "root"
    msg = "Running as root user is not allowed"
}

deny[msg] {
    input[i].Cmd == "run"
    val := input[i].Value
    contains(val[0], "sudo")
    msg = "sudo usage is not recommended"
}
