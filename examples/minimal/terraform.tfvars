
# You can also rely solely on .env + Make targets.
# This file shows explicit variables you could pass with -var-file.

cluster_name = "trade-ams-prod"
region       = "ams3"
node_size    = "s-1vcpu-2gb"
min_nodes    = 1
max_nodes    = 2

enable_bot         = true
enable_cloudflared = true

bot_namespace = "bot-demo"
bot_name      = "bot-demo"
bot_strategy  = "SampleStrategy"

cloudflare_mappings = [
  { host = "bot-dev.quadr.app", service_name = "freqtrade-bot-bot-demo", service_port = 8080 }
]
