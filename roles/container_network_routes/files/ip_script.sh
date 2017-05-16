#!/bin/bash
kubectl get nodes   --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}' > /tmp/nodes-routes

