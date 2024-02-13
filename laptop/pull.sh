#!/usr/bin/env bash

echo ">: Installing git and ansible..."
sudo apt update
sudo apt install git python3 python3-pip python3-setuptools sshpass -y
sudo pip3 install ansible --break-system-packages

echo ">: Pulling ansible provisioning/bootstrap..."
bootstrap_directory="/tmp/bootstrap"
mkdir -p ${bootstrap_directory}
cd ${bootstrap_directory}
git clone https://github.com/sndnv/provision.git
cd ${bootstrap_directory}/provision/laptop
