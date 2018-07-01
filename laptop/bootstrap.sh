#!/usr/bin/env bash

total_memory=$(awk '/MemTotal/ {print $2 / 1000 / 1000}' /proc/meminfo)
total_memory=${total_memory%.*}

declare -a params_list=(
    "primary_device"
    "secondary_device_type"
    "secondary_device"
    "root_vg_swap_size"
    "root_vg_root_size"
    "root_vg_home_size"
    "encryption_password"
    "verify_encryption_password"
)

declare -A param_descriptions
param_descriptions=(
    ["primary_device"]="Primary [root] device"
    ["secondary_device_type"]="Secondary device type [home|data|skip]"
    ["secondary_device"]="Secondary device (path to device, 'skip' or '')"
    ["root_vg_swap_size"]="Partition [swap] size on root VG (with units [bBsSkKmMgGtTpPeE])"
    ["root_vg_root_size"]="Partition [root] size on root VG (with units [bBsSkKmMgGtTpPeE])"
    ["root_vg_home_size"]="Partition [home] size on root VG (with units [bBsSkKmMgGtTpPeE])"
    ["encryption_password"]="Encryption password"
    ["verify_encryption_password"]="Encryption password (verify)"
)

declare -A params

defaults () {
    param_name=$1

    declare -A default_params
    default_params=(
        ["primary_device"]="/dev/sda"
        ["secondary_device_type"]="skip"
        ["secondary_device"]=$([[ ${params["secondary_device_type"]} = "skip" ]] && echo "skip" || echo "")
        ["root_vg_swap_size"]="${total_memory}g"
        ["root_vg_root_size"]=$([[ ${params["secondary_device_type"]} != "home" ]] && echo "60g" || echo "100%FREE")
        ["root_vg_home_size"]=$([[ ${params["secondary_device_type"]} != "home" ]] && echo "100%FREE" || echo "")
    )

    echo ${default_params[$param_name]}
}

for param in ${params_list[@]}; do
    param_default=$(defaults ${param})

    if [[ $param = *"password"* ]]; then
        read -s -p "${param_descriptions[${param}]} [${param_default}]: " param_input
        echo
    else
        read -p "${param_descriptions[${param}]} [${param_default}]: " param_input
    fi

    if [[ -z "${param_input}" ]]; then
        params[${param}]="${param_default}"
    else
        params[${param}]="${param_input}"
    fi
done

if [[ -z "${params["encryption_password"]}" ]]; then
    echo "Error: Encryption password is required."
    exit 1
fi

if [[ "${params["encryption_password"]}" != "${params["verify_encryption_password"]}" ]]; then
    echo "Error: Encryption passwords do not match."
    exit 2
fi

if [[ "${params["primary_device"]}" = "${params["secondary_device"]}" ]]; then
    echo "Error: Cannot use device [${params["primary_device"]}] as both primary and secondary device."
    exit 3
fi

echo
echo -e ">: Device [${params['primary_device']}]:"
echo -e ">: \t Delete and recreate: \t yes"
echo -e ">: \t Swap volume size: \t ${params['root_vg_swap_size']}"
echo -e ">: \t Root volume size: \t ${params['root_vg_root_size']}"
echo -e ">: \t Home volume size: \t ${params['root_vg_home_size']:-<none>}"
echo

if [[ "${params["secondary_device"]}" = 'skip' ]] || [[ "${params["secondary_device"]}" = '' ]]; then
    echo -e ">: Skipping secondary device"
    echo
else
    echo -e ">: Device [${params['secondary_device']}]:"
    echo -e ">: \t Delete and recreate: \t yes"
    echo -e ">: \t Volume size: \t\t 100%FREE"
    echo
fi

echo ">: All configured devices will be encrypted!"
echo

while [[ "${bootstrap_confirm}" != 'yes' ]] && [[ "${bootstrap_confirm}" != 'no' ]] ; do
    read -p "Are you sure you want to continue (yes/no)?: " bootstrap_confirm
done

if [[ "${bootstrap_confirm}" != "yes" ]]; then
    echo ">: Bootstrap cancelled"
    exit 4
fi

bootstrap_directory="/tmp/bootstrap"

echo ">: Creating encryption keyfile..."
encryption_keyfile="/root/encryption_keyfile"
sudo touch ${encryption_keyfile}
sudo chown root:root ${encryption_keyfile}
sudo chmod 0400 ${encryption_keyfile}
echo -n "${params["encryption_password"]}" | sudo dd of=${encryption_keyfile} status=none

echo ">: Starting ansible bootstrap..."
ansible-playbook \
    bootstrap.yml \
    --extra-vars "primary_device=${params['primary_device']} \
                  secondary_device=${params['secondary_device']} \
                  secondary_device_type=${params['secondary_device_type']} \
                  root_vg_swap_size=${params['root_vg_swap_size']} \
                  root_vg_root_size=${params['root_vg_root_size']} \
                  root_vg_home_size=${params['root_vg_home_size']} \
                  encryption_keyfile=${encryption_keyfile} \
                  bootstrap_directory=${bootstrap_directory}"

sudo shred -u -f ${encryption_keyfile} 2> /dev/null
