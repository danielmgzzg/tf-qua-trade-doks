
# examples/minimal

Deploys:
- DOKS (1 node, autoscale 1–2)
- cloudflared (token from Doppler)
- one Freqtrade bot (dry-run)

Run:

```bash
cp ../../.example.env ../../.env
# fill in DO_TOKEN and DOPPLER_TOKEN at repo root .env
make -C ../.. init
make -C ../.. apply
```
