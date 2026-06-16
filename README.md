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

The v8s.link account ID, zone ID, hostname, and Worker name are committed as
defaults in `variables.tf`. Copy `terraform.tfvars.example` to
`terraform.tfvars`, replace the maintainer email list, then run:

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

Set the token as an environment variable before planning:

```bash
export CLOUDFLARE_API_TOKEN="..."
```

The existing DNSControl token can read v8s.link DNS and zone rulesets, but it
does not have Zero Trust Access permissions. Use a Terraform-specific token
before importing or applying the Access application.

## Current Discovery

The current v8s.link zone metadata is:

| Setting               | Value                              |
| --------------------- | ---------------------------------- |
| Cloudflare account ID | `48aa42c6cec6d260e6f97abf3d8cdc6b` |
| Cloudflare zone ID    | `60fc561443676fe33f3c195b766a3418` |
| Apex hostname         | `v8s.link`                         |
| Worker name           | `v8s-link`                         |
| Access team domain    | `vanityurls.cloudflareaccess.com`  |

The current zone rulesets API result only showed Cloudflare-managed rulesets for
normalization, managed WAF, and DDoS. No existing custom redirect, WAF custom, or
rate-limit rulesets were visible with the DNSControl token.

Live DNS currently resolves `v8s.link`, but `www.v8s.link` does not resolve. The
Terraform redirect rule for `www.v8s.link` will only become effective after a
proxied `www` DNS record exists in the zone. If DNS stays managed by DNSControl,
add that record or ignore it there before Terraform owns it here.

Zero Trust Access discovery returned an authentication error with the DNSControl
token, so check/import the Access application with a token that has Access
application and policy read permissions before the first apply.

## Import Checklist

Before the first apply, import any existing Cloudflare resources that already
match this config. Importing avoids duplicate Access applications or rulesets.

Use these addresses when the matching Cloudflare resources already exist:

```bash
terraform import cloudflare_zero_trust_access_application.vanityurls_private_paths "<account_id>/<access_application_id>"
terraform import cloudflare_ruleset.redirect_www_to_apex "<zone_id>/<ruleset_id>"
terraform import cloudflare_ruleset.custom_waf "<zone_id>/<ruleset_id>"
terraform import cloudflare_ruleset.rate_limit_short_link_candidates "<zone_id>/<ruleset_id>"
```

If the custom rulesets do not exist, let Terraform create them during the first
apply after reviewing the plan.

After applying Access changes, store the Access audience as a Worker secret in
the redirector repo:

```bash
npx wrangler secret put CF_ACCESS_AUD --config wrangler.toml
```

## Operations

Terraform should own the Cloudflare resources represented here once they are
imported. Dashboard changes should be treated as emergency edits and reconciled
back into Terraform afterward.
