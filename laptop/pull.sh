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
sudo apt install software-properties-common -y
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install git -y
sudo apt install ansible -y

echo ">: Pulling ansible provisioning/bootstrap..."
bootstrap_directory="/tmp/bootstrap"
mkdir -p ${bootstrap_directory}
cd ${bootstrap_directory}
git clone https://github.com/sndnv/provision.git
cd ${bootstrap_directory}/provision/laptop
