# cardano-node

Build Binary
------------
VERSION=1.26.2
docker build -t dshiell/cardano-node:${VERSION} .

docker run -v $(pwd)/bin:/tmp --entrypoint /bin/cp dshiell15/cardano-node:${VERSION} /usr/local/bin/cardano-cli /tmp/
docker run -v $(pwd)/bin:/tmp --entrypoint /bin/cp dshiell15/cardano-node:${VERSION} /usr/local/bin/cardano-node /tmp/
docker run -v $(pwd)/bin:/tmp --entrypoint /bin/cp dshiell15/cardano-node:${VERSION} /lib/aarch64-linux-gnu/libsodium.so.23 /tmp/

User Setup
----------


Systemd Setup
-------------
loginctl enable-linger <user>

Links
-----
- https://serverfault.com/questions/892465/starting-systemd-services-sharing-a-session-d-bus-on-headless-system/906224#906224
- https://computingforgeeks.com/how-to-run-systemd-service-without-root-sudo/