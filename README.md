# cardano-node
Playing with running Cardano cluster with K3s on Raspberry Pi 4's

# Build the base image
docker build -t cardano-node-base .

# Build minified scratch images for cardano-cli and cardano-node
docker build -t cardano-node -f Dockerfile.node .
docker build -t cardano-cli -f Dockerfile.cli .