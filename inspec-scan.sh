#!/bin/bash
mkdir -p k8s-deploy-audit
inspec exec https://github.com/dev-sec/kubernetes-baseline \
    --chef-license accept-silent \
    --reporter json:k8s-deploy-audit/inspec.json \
    --reporter junit:k8s-deploy-audit/inspec-junit.xml
