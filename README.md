# cardano-node
Playing with running Cardano cluster with K3s on Raspberry Pi 4's

# Build minified scratch images for cardano-cli and cardano-node (time for a nap...)
docker build -t cardano-node .

1. ./setup-pool-env.sh
2. ./start-relay.sh
3. create operational cert
4. ./start-producer.sh
