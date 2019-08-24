#!/usr/bin/env bash

if [[ "$1" == "--help" ]]; then
    echo -e "Usage: $0 [--help | --with-sshpass]"
    echo -e "\t --help \t\t shows this help message"
    echo -e "\t --with-sshpass \t installs sshpass (needed if it fails to install as an ansible dependency)"
    exit 0
elif [[ "$1" == "--with-sshpass" ]]; then
    echo ">: Downloading and installing sshpass..."
    wget http://security.ubuntu.com/ubuntu/pool/universe/s/sshpass/sshpass_1.06-1_amd64.deb
    sudo dpkg -i sshpass_1.06-1_amd64.deb
    sudo apt --fix-broken install
fi

echo ">: Installing git and ansible..."
sudo apt update
sudo apt install git python3 python3-pip python3-setuptools -y
sudo pip3 install ansible=2.7.11

echo ">: Pulling ansible provisioning/bootstrap..."
bootstrap_directory="/tmp/bootstrap"
mkdir -p ${bootstrap_directory}
cd ${bootstrap_directory}
git clone https://github.com/sndnv/provision.git
cd ${bootstrap_directory}/provision/laptop
