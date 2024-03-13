# bor-sidecar

A sidecar container suitable to monitor heimdall & bor nodes.

```
environment:
  - HEIMDALL_URL=http://polygon_heimdall_daemon-{{ .Node.Hostname }}:26657/status
  - BOR_URL=http://polygon_bor-{{ .Node.Hostname }}:8545/
```
