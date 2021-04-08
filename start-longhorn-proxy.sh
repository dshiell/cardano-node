#!/bin/sh
kubectl -n longhorn-system port-forward svc/longhorn-frontend 80:8080