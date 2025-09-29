#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DIR}/.."

# Get the kubeconfig for the EKS cluster
echo "Generating kubeconfig..."
"${REPO_ROOT}/terraform/scripts/generate-kubeconfig.sh"

# Ensure External Secrets CRDs exist (installed by operators stack)
echo "Waiting for External Secrets CRDs to be available..."
for i in {1..24}; do # up to ~2 minutes
	if kubectl get crd clustersecretstores.external-secrets.io >/dev/null 2>&1; then
		break
	fi
	sleep 5
	if [[ $i -eq 24 ]]; then
		echo "Timed out waiting for External Secrets CRDs. Ensure operators stack is applied." >&2
		exit 1
	fi
done

# Ensure application namespace exists before applying ExternalSecrets
kubectl apply -f "${REPO_ROOT}/k8s/base/namespaces/retail-store.yaml"

# Apply ClusterSecretStore (points ESO to AWS Secrets Manager in eu-west-1)
kubectl apply -f "${REPO_ROOT}/k8s/operators/external-secrets/clustersecretstore.yaml"

# Wait for the ClusterSecretStore to become Ready (IRSA must be functional)
echo "Waiting for ClusterSecretStore to be Ready..."
for i in {1..24}; do # up to ~2 minutes
	STATUS=$(kubectl get clustersecretstore innovatemart-cluster-secret-store -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)
	if [[ "$STATUS" == "True" ]]; then
		echo "ClusterSecretStore is Ready."
		break
	fi
	sleep 5
	if [[ $i -eq 24 ]]; then
		echo "Timed out waiting for ClusterSecretStore to be Ready. Check ESO logs and IRSA/OIDC setup." >&2
		kubectl describe clustersecretstore innovatemart-cluster-secret-store || true
		exit 1
	fi
done

# Prime ExternalSecrets first to avoid workload restart loops on missing secrets
echo "Applying ExternalSecrets for app configs..."
kubectl apply -f "${REPO_ROOT}/k8s/base/config/external-secrets/catalog-db-secret.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/base/config/external-secrets/orders-db-secret.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/base/config/external-secrets/carts-ddb-secret.yaml"

echo "Waiting for target Secrets to be created by External Secrets..."
for name in catalog-db-secret orders-db-secret carts-ddb-secret; do
	kubectl -n retail-store wait --for=condition=Ready secret/$name --timeout=120s >/dev/null 2>&1 || true
	# Fallback check: existence
	for i in {1..24}; do
		if kubectl -n retail-store get secret "$name" >/dev/null 2>&1; then
			break
		fi
		sleep 5
	done
done

# Deploy the application (services, deployments, etc.)
echo "Deploying the retail store application..."

kubectl apply -k "${REPO_ROOT}/k8s/overlays/sandbox"

# Scale down AWS Load Balancer Controller to avoid pod scheduling issues during deployment
kubectl -n kube-system scale deployment/aws-load-balancer-controller --replicas=0

echo "✅ Application deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Check application status: kubectl get pods -n retail-store"
echo "2. Get service URLs: kubectl get services -n retail-store"
echo "3. Check ingress: kubectl get ingress -n retail-store"
echo "4. View logs: kubectl logs -n retail-store deployment/ui"
echo ""
echo "For DuckDNS domain setup:"
echo "1. Get free domain at duckdns.org (e.g., innovatemarts.duckdns.org)"
echo "2. Configure in terraform/envs/operators/terraform.tfvars"
echo "3. Run: cd terraform/envs/operators && terraform apply"
echo "4. See docs/DUCKDNS_SETUP.md for detailed instructions"
echo ""
echo "Access your application at: http://innovatemarts.duckdns.org:30080"