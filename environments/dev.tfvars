cluster_name = "trade-ams-dev"
region       = "ams3"
node_size    = "s-1vcpu-2gb"
min_nodes    = 1
max_nodes    = 2

enable_bot         = true
enable_cloudflared = true

bot_namespace = "bots-dev"

cloudflare_mappings = [
  { host = "bot-dev.quadr.app", service_name = "freqtrade-bot-btc-demo", service_port = 8080 }
]

freqtrade_bots = {
  "btc-dev" = {
    strategy       = "SampleStrategy"
    live           = false
    pair_whitelist = ["BTC/USDT"]
  }
}
