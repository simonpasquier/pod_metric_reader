#!/usr/bin/env bash
set -eu -o pipefail

declare SHOW_USAGE=false
declare NAMESPACES=16
declare PODS=1
declare SECRETS=16
declare SECRET_SIZE=1024

parse_args() {
	### while there are args parse them
	while [[ -n "${1-}" ]]; do
		case $1 in
			-h | --help)
			SHOW_USAGE=true
			# exit the loop
			break
			;;
		--namespaces | -n)
			shift
			NAMESPACES=$1
			shift
			;;
		--pods | -p)
			shift
			PODS=$1
			shift
			;;
		--secrets | -s)
			shift
			SECRETS=$1
			shift
			;;
		--secret-size)
			shift
			SECRET_SIZE=$1
			shift
			;;
		*)
			shift
			;;
		esac
	done
	return 0
}

show_usage() {
	local name
	name="$(basename "$0")"

	read -r -d '' help <<-EOF_HELP || true
Usage:
────────────────────────────────────────────
  ❯ $name [--namespaces <number>] [--secrets <number>] [--secret-size <number>]
  ❯ $name  -h|--help

Options:
⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻
  --help | -h         Show this help
  --namespaces | -n: Defines the number of namespaces to generate.
  --pods | -p:       Defines the number of pods (per namespace) to generate.
  --secrets | -s:    Defines the number of secrets (per namespace) to generate.
  --secret-size:     Defines the size (in bytes) of secret data

EOF_HELP

	echo -e "$help"
	return 0
}

parse_args "$@" || {
	show_usage
	exit 1
}

generate_random() {
    tr -dc '[:alpha:]' < /dev/urandom | fold -w "$1" | head -n 1
}

$SHOW_USAGE && {
	show_usage
	exit 0
}

echo "Generating manifests with $NAMESPACES namespaces, $PODS pods and $SECRETS secrets..."

rm -f ns.yaml pods.yaml secrets.yaml

for i in $(seq 1 "$NAMESPACES"); do
  cat <<EOF >> ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: test-$i
  labels:
    kubernetes.io/name: test
EOF

  for j in $(seq 1 "$PODS"); do
    cat <<EOF >> pods.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: test-$j
  namespace: test-$i
  labels:
    kubernetes.io/name: test
spec:
  containers:
  - name: empty
    image: public.ecr.aws/docker/library/alpine:latest
    command: ["sleep", "100000"]
    imagePullPolicy: IfNotPresent
EOF
  done

  for j in $(seq 1 "$SECRETS"); do
    cat <<EOF >> secrets.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: test-$j
  namespace: test-$i
  annotations:
    kubernetes.io/description: $(generate_random 1024)
  labels:
    kubernetes.io/name: test
stringData:
  key: |-
    $(generate_random "$SECRET_SIZE")
EOF
  done
done
