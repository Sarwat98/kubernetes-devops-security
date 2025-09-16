#!/bin/bash

echo "=== Running InSpec Infrastructure Compliance Scan ==="

inspec exec \
    --chef-license accept \
    --chef-license-key "free-09f87d44-2b4f-4c9a-bfd4-f3f8f222ea24-6265" \
    https://github.com/dev-sec/linux-baseline \
    --target ssh://user@target-host \
    --key-files ~/.ssh/id_rsa \
    --reporter json:inspec-results.json cli

echo "✅ InSpec scan completed"
