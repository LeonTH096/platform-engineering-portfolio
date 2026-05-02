# ADR-0003: Use GitHub OIDC authentication over long-lived credentials

## Status

Accepted

## Date

2026-05-02

## Context

GitHub Actions workflows need to authenticate to Azure to deploy infrastructure
(Terraform/Terragrunt) and push container images (ACR). Two approaches exist:

1. **Long-lived credentials** — Create an Azure Service Principal, generate a
   client secret, store it as a GitHub Actions secret (`AZURE_CLIENT_SECRET`).
   Simple to set up, but the secret is a static credential that can be leaked,
   never rotates automatically, and must be manually renewed before expiry.

2. **OIDC federation** — Configure a federated identity credential on an Azure
   Service Principal (or Managed Identity) that trusts GitHub's OIDC provider.
   GitHub Actions requests a short-lived token from GitHub's OIDC endpoint,
   presents it to Azure AD, and receives a short-lived Azure access token.
   No static secrets are stored anywhere.

## Decision

Use GitHub OIDC federation with an Azure Service Principal for all CI/CD
authentication. No long-lived client secrets will be stored in GitHub Actions
secrets.

Implementation:
- Azure Service Principal with federated identity credential
- Trust policy scoped to: `repo:LeonTH096/platform-engineering-portfolio:ref:refs/heads/main`
- GitHub Actions workflow uses `azure/login@v2` with `client-id`, `tenant-id`,
  and `subscription-id` (all non-secret values)

## Consequences

### Positive

- No static secrets to leak, rotate, or expire
- Short-lived tokens (valid ~60 minutes) limit blast radius of compromise
- Industry best practice endorsed by both Microsoft and GitHub
- Demonstrates zero-trust authentication thinking to hiring managers
- Consistent with the broader identity pattern (Workload Identity for AKS pods)

### Negative

- More complex initial setup (federated credential configuration in Azure AD)
- Trust policy must be carefully scoped (misconfigured policy = any GitHub repo
  can authenticate)
- Debugging token exchange failures is less intuitive than "wrong password"

### Neutral

- Works identically for Terraform, Helm, and Docker push workflows
- Same pattern applies to AWS (if AWS access returns): `aws-actions/configure-aws-credentials`
  with `role-to-assume` instead of access keys

## References

- [GitHub OIDC with Azure](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure federated identity credentials](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [azure/login action](https://github.com/Azure/login)
