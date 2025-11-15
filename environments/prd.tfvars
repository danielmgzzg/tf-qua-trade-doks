cluster_name = "trade-ams"
region       = "ams3"
node_size    = "s-2vcpu-4gb"
min_nodes    = 1
max_nodes    = 2

enable_bot         = true
enable_cloudflared = true

bot_namespace = "bots"

cloudflare_mappings = [
  { host = "bot.quadr.app", service_name = "freqtrade-bot-btc", service_port = 8080 },
  { host = "bot-btc-dev.quadr.app", service_name = "freqtrade-bot-btc-dev", service_port = 8080 }
]

freqtrade_bots = {
  "btc" = {
    strategy       = "BasicStrategy"
    live           = true
    pair_whitelist = ["BTC/USDT"]
  },
  "btc-dev" = {
    strategy       = "BasicStrategy"
    live           = false
    pair_whitelist = ["BTC/USDT"]
  }
}
