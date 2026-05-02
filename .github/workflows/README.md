# GitHub Actions Workflows

CI/CD pipeline definitions for both projects.

## Planned workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `terraform-validate.yml` | PR to `main` | Lint and validate Terraform/Terragrunt code |
| `terraform-plan.yml` | PR to `main` | Run `terraform plan` and post output to PR |
| `terraform-apply.yml` | Push to `main` | Apply infrastructure changes |
| `helm-lint.yml` | PR to `main` | Lint and validate Helm charts |
| `helm-deploy.yml` | Push to `main` | Deploy Helm releases to AKS |
| `docker-build.yml` | PR/push | Build and push container images to ACR |

All workflows authenticate to Azure via OIDC (no stored secrets).
See [ADR-0003](../../docs/adr/0003-github-oidc-over-long-lived-credentials.md).
