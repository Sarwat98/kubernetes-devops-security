package main

# Do Not store secrets in ENV variables
secrets_env := {
  "passwd", "password", "pass", "secret", "key",
  "access", "api_key", "apikey", "token", "tkn"
}

deny contains msg if {
  some i
  input[i].Cmd == "env"
  val := input[i].Value
  some j
  contains(lower(val[j]), secrets_env[_])
  msg := sprintf("Line %d: Potential secret in ENV key found: %v", [i, val])
}

# Only use trusted base images
# deny contains msg if {
#   some i
#   input[i].Cmd == "from"
#   parts := split(input[i].Value[0], "/")
#   count(parts) > 1
#   msg := sprintf("Line %d: use a trusted base image", [i])
# }

# Do not use 'latest' tag for base images
deny contains msg if {
  some i
  input[i].Cmd == "from"
  parts := split(input[i].Value[0], ":")
  count(parts) > 1
  contains(lower(parts[1]), "latest")
  msg := sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

# Avoid curl bashing
deny contains msg if {
  some i
  input[i].Cmd == "run"
  val := concat(" ", input[i].Value)
  matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
  count(matches) > 0
  msg := sprintf("Line %d: Avoid curl bashing", [i])
}

# Do not upgrade your system packages
warn contains msg if {
  some i
  input[i].Cmd == "run"
  val := concat(" ", input[i].Value)
  regex.match(".*?(apk|yum|dnf|apt|pip).+?(install|(?:dist-|check-|group)?up(?:grade|date)).*", lower(val))
  msg := sprintf("Line %d: Do not upgrade your system packages: %s", [i, val])
}

# Do not use ADD if possible
deny contains msg if {
  some i
  input[i].Cmd == "add"
  msg := sprintf("Line %d: Use COPY instead of ADD", [i])
}

# Any user present?
any_user if {
  some i
  input[i].Cmd == "user"
}

deny contains msg if {
  not any_user
  msg := "Do not run as root, use USER instead"
}

# ... but do not root
forbidden_users := {"root", "toor", "0"}

deny contains msg if {
  users := [name | some i; input[i].Cmd == "user"; name := input[i].Value]
  count(users) > 0
  lastuser := users[count(users)-1]
  some k
  contains(lower(lastuser[k]), forbidden_users[_])
  msg := sprintf("Line %d: Last USER directive (USER %s) is forbidden", [count(users)-1, lastuser])
}

# Use multi-stage builds
# default multi_stage := false

# multi_stage if {
#   some i
#   input[i].Cmd == "copy"
#   flags := concat(" ", input[i].Flags)
#   contains(lower(flags), "--from=")
# }

# deny contains msg if {
#   not multi_stage
#   msg := "You COPY, but do not appear to use multi-stage builds..."
# }
