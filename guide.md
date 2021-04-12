1. How to manage nodes from different VLAN? - DONE
2. Disable passwords, create new users and use ssh keys for logging in - DONE
3. setup k3s
4. Create pool cold keys, KES key, VRF key (kes.skey  kes.vkey  node.cert  vrf.skey  vrf.vkey)
5. Store KES key on secure USB
6. How will metrics be accessible? Alerting? Can I alert myself via text message automatically? Pagerduty?
7. Change ssh port on block node to non 22
8. buy 2 secure usbs for stake pool keys - DONE
9. install security updates regularly
10. KES key needs to be updated every 90 days. 
11. Use Port triggering for Cardano VLAN.
12. Make stake pool website.

Prerequisites
-------------

1. Guide is for MAC, install brew
2. 

Inter VLAN routing
------------------

- How to manage RPI's on separate VLAN. WiFi
- Added ACL's to allow SSH from default VLAN --> Cardano VLAN
- 

Update packages/create user
---------------------------

#apt-get install unattended-upgrades?

sudo adduser --home /home/cardano --ingroup admin cardano
sudo deluser --remove-home ubuntu
sudo apt-get install open-iscsi
sudo apt-get upgrade

Setup hostname
--------------
echo <hostname> > /etc/hostname
sudo reboot

Setup passwordless ssh
----------------------
ssh-keygen --> id_rsa/id_rsa.pub
copy id_rsa.pub --> ~/.ssh/authorized_keys

RPI:
sudo vi /etc/ssh/sshd_config
  ChallengeResponseAuthentication no
  PasswordAuthentication no
  UsePAM no
  PermitRootLogin no

sudo systemctl reload ssh
sudo systemctl reload sshd

Local:
create .ssh/config --> example

logout/login

SSD Formatting
--------------

- sudo parted /dev/sda mklabel gpt
- sudo parted -a opt /dev/sda mkpart primary ext4 0% 100%
- sudo mkfs.ext4 -L data /dev/sda1
- sudo mkdir /data
- sudo bash -c "echo 'LABEL=data        /data ext4 defaults 0 2 ' >> /etc/fstab"
- sudo mount -a
- sudo chown -R cardano:admin /data needed?

Enable Cgroups
--------------
- enable cgroups on rpi
sudo bash -c 'echo "cgroup_memory=1 cgroup_enable=memory cgroup_enable=cpuset" >> /boot/firmware/cmdline.txt' # /boot/cmdline.txt on raspberry pi os
sudo reboot

Installing K3s
--------------

on each node install curl -sfL https://get.k3s.io | sh - --disable servicelb

sudo systemctl status k3s
sudo cat /var/lib/rancher/k3s/server/node-token

install kubectl for OS

Internet
--------
Allow port 6443 for kubectl

echo "cardano ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/cardano
k3sup needs passwordless sudoer priviledges

k3sup install 


Installing Longhorn
-------------------
https://www.publish0x.com/awesome-self-hosted/longhorn-on-k3s-xwqdjyj

from dev box:
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.0.0/scripts/environment_check.sh | bash

kubectl create namespace longhorn-system
helm upgrade --install -n longhorn-system -f k8s/longhorn-io-values.yaml longhorn longhorn/longhorn

Install Prometheus + Grafana
----------------------------

- kubectl create namespace monitoring
- helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
- helm repo add stable https://charts.helm.sh/stable
- helm update
- helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring 
- kubectl --namespace monitoring get pods

