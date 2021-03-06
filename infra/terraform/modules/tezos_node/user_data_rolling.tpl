#!/bin/bash -ex

# Setup Docker, aws CLI and utilitary tools

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce unzip jq --nobest -y
systemctl enable --now docker
usermod -aG docker ec2-user

curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Setup lambda ssh key

mkdir -p ~/.ssh && chmod 700 ~/.ssh
bash -c '
echo "${lambda_public_key}" >> /home/ec2-user/.ssh/authorized_keys
'

# Install Tezos docker-compose wrapper

curl -o /usr/local/bin/${network}.sh https://gitlab.com/tezos/tezos/raw/latest-release/scripts/tezos-docker-manager.sh
chmod +x /usr/local/bin/${network}.sh

cd /home/ec2-user

# Import snapshot from the S3 bucket

aws s3 cp s3://tzlink-blockchain-data-dev/${network}_rolling-snapshot.tar.gz ${network}_rolling-snapshot.tar.gz
tar xvf ${network}_rolling-snapshot.tar.gz
rm ${network}_rolling-snapshot.tar.gz

# Dry start to load the snapshot

${network}.sh node start --rpc-port 8000 --history-mode experimental-rolling
${network}.sh stop

if [ -f "/var/lib/docker/volumes/carthagenet_node_data/_data/data/lock" ]; then
  sudo rm -f /var/lib/docker/volumes/carthagenet_node_data/_data/data/lock
fi

if [ -f "/var/lib/docker/volumes/carthagenet_node_data/_data/data/context" ]; then
  sudo rm -rf /var/lib/docker/volumes/carthagenet_node_data/_data/data/context
fi

if [ -f "/var/lib/docker/volumes/carthagenet_node_data/_data/data/store" ]; then
  sudo rm -rf /var/lib/docker/volumes/carthagenet_node_data/_data/data/store
fi

${network}.sh snapshot import /home/ec2-user/snapshot.rolling

# Start tezos node in rolling mode

${network}.sh node start --rpc-port 8000 --history-mode experimental-rolling

rm snapshot.rolling