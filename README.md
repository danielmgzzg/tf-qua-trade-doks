
# tf-port-doks-minimal

Minimal, toggleable Terraform stack to deploy:
- **DigitalOcean DOKS** cluster (free control plane).
- **Cloudflared** (Cloudflare Tunnel) with token pulled from **Doppler**.
- **One Freqtrade bot** in **dry-run** mode (no secrets needed).

> Start cheap: 1× `s-1vcpu-2gb` node (≈ $12/mo) and no paid load balancer.

## Prereqs
- Terraform >= 1.6
- DigitalOcean Personal Access Token
- Doppler service token with read access to a project/config containing
  `CLOUDFLARE_TUNNEL_TOKEN`
- Cloudflare Tunnel created in your account (retrieve its **connector token**)

## Quick start
```bash
cp .example.env .env
# edit .env with your tokens and settings
make init
make apply
```

The bot UI is exposed at the hostname you configure in `cloudflare_mappings`
(default: `bot.example.com`). Point a Cloudflare DNS record to your tunnel route.

## Toggles
- `enable_cloudflared` (default **true**)
- `use_doppler_for_cloudflared` (default **true**) – set to **false** to provide
  `cloudflare_tunnel_token` directly instead of using Doppler
- `enable_bot` (default **true**)

## How the Doppler integration works
- The `doppler` provider reads all secrets for `doppler_project`/`doppler_config`
- We look up `var.doppler_cloudflare_token_key` (default `CLOUDFLARE_TUNNEL_TOKEN`)
- We create a K8s Secret `cloudflared-token` with key `token`
- The `cloudflared` Helm chart is installed pointing at that Secret

## Structure
```
modules/
  cluster/do_doks         # DOKS cluster
  addons/cloudflared_tunnel  # Helm release for cloudflared
  apps/freqtrade_bot      # Local Helm chart + release
examples/minimal          # tfvars example (optional)
```

## Notes
- Chart used for cloudflared: `cloudflare/cloudflared`
- Terraform uses the Doppler provider to read the token, so the value never
  needs to be committed to git.
- The freqtrade bot runs in **dry-run** by default. Switch to live later by
  setting a `secret_ref` and changing `mode` to `live` (via module/Helm values).
