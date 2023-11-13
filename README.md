This project contains 2 parts:
* `pod_metric_reader`, simple client to make concurrent requests to the Kubernetes Pod metrics API (e.g. `pods.metrics.k8s.io`).
* `generate_manifests.sh`, Shell script to generate random namespaces, pods and secrets.

The initial motivation for this project was to investigate and reproduce performance issues with the Kubernetes Prometheus adapter.

The project is licensed under the Apache v2 License.
