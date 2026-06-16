# v8s-config

Terraform source of truth for the Cloudflare configuration behind the v8s.link
reference/demo instance of vanityURLs.

This repo is intentionally separate from the reusable redirector source repo and
the public documentation repo:

- `vanityURLs/code` contains the reusable Worker redirector.
- `vanityURLs/website` contains public documentation.
- `v8s-config` owns the live Cloudflare configuration for the v8s.link demo.

## Managed Cloudflare Controls

- Cloudflare Access protects private operational paths.
- A redirect rule sends `www` traffic to the apex hostname.
- WAF custom rules block scanner probes, unexpected methods, and suspicious
  script clients before requests reach the Worker.
- A rate limiting rule protects likely short-link candidates.

The baseline uses `block`, not `managed_challenge`, for script-client rules.
Managed challenges can inject Cloudflare JavaScript into matching HTML responses,
which conflicts with repository-owned CSP and deterministic public pages.

Use Cloudflare AI Crawl Control for AI crawler blocking. The optional static
user-agent rule is disabled by default because it can drift from Cloudflare's
managed crawler inventory and can cause the AI Crawl Control dashboard to report
that the underlying WAF rule was modified outside AI Crawl Control.

## Local Setup

Copy `terraform.tfvars.example` to `terraform.tfvars`, replace the placeholders,
then run:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

The Cloudflare provider expects an API token with the least permissions needed
for the resources enabled here. For this config, start with zone rules, zone
settings, and Zero Trust Access application/policy permissions for the target
account and zone.

After applying Access changes, store the Access audience as a Worker secret in
the redirector repo:

```bash
npx wrangler secret put CF_ACCESS_AUD --config wrangler.toml
```

## Operations

Terraform should own the Cloudflare resources represented here once they are
imported. Dashboard changes should be treated as emergency edits and reconciled
back into Terraform afterward.
