.PHONY: tflint
tflint:
	tflint --init && tflint -f compact

.PHONY: tfsec
tfsec:
	tfsec .

.PHONY: visualize
visualize:
	chmod +x ./visualize.sh && ./visualize.sh

.PHONY: run-actions-locally
run-actions-locally:
	act --env GITHUB_RUN_ATTEMPT=1 -s GITHUB_TOKEN="$(gh auth token)" --secret-file=act-secrets.env

