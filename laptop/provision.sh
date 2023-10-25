#!/usr/bin/env bash

declare -a params_list=(
    "target_user_full_name"
    "nas_hostname"
    "nas_mount_target"
    "cifs_user"
    "secondary_volume_type"
    "secondary_volume_name"
    "secondary_volume_partition"
    "encryption_password"
)

declare -A param_descriptions
param_descriptions=(
    ["target_user"]="Target user"
    ["target_user_full_name"]="Target user full name"
    ["nas_name"]="NAS name"
    ["nas_hostname"]="NAS hostname"
    ["nas_mount_target"]="NAS mount target"
    ["cifs_user"]="NAS/CIFS username"
    ["secondary_volume_type"]="Secondary volume type [home|data|skip]"
    ["secondary_volume_name"]="Secondary volume name"
    ["secondary_volume_partition"]="Secondary volume partition (ex: /dev/sdb1)"
    ["encryption_password"]="Encryption password for secondary volume"
)

declare -A params

defaults () {
    param_name=$1

    declare -A default_params
    default_params=(
        ["target_user"]="$(whoami)"
        ["target_user_full_name"]="${params["target_user"]}"
        ["nas_name"]=""
        ["nas_hostname"]="${params["nas_name"]}.internal"
        ["nas_mount_target"]="/mnt/${params["nas_name"]}"
        ["cifs_user"]="${params["target_user"]}"
        ["secondary_volume_type"]="skip"
        ["secondary_volume_name"]=$([[ ${params["secondary_volume_type"]} != "skip" ]] && echo "${params["secondary_volume_type"]}_crypt" || echo "skip")
        ["secondary_volume_partition"]=$([[ ${params["secondary_volume_type"]} != "skip" ]] && echo "" || echo "skip")
        ["encryption_password"]=$([[ ${params["secondary_volume_type"]} != "skip" ]] && echo "" || echo "skip")
    )

    echo ${default_params[$param_name]}
}

if [[ -z "${TARGET_USER}" ]]; then
    param_default=$(defaults "target_user")

    read -p "${param_descriptions["target_user"]}: " -i ${param_default} -e target_user_input

    if [[ -z "${target_user_input}" ]]; then
        echo "Error: Target user is required."
        exit 1
    else
        params["target_user"]="${target_user_input}"
    fi
else
    params["target_user"]="${target_user_input}"
fi

if [[ -z "${NAS_NAME}" ]]; then
    param_default=$(defaults "nas_name")

    read -p "${param_descriptions["nas_name"]} [${param_default}]: " nas_name_input

    if [[ -z "${nas_name_input}" ]]; then
        echo "Error: NAS name is required."
        exit 2
    else
        params["nas_name"]="${nas_name_input}"
    fi
else
    params["nas_name"]="${nas_name_input}"
fi

for param in ${params_list[@]}; do
    param_default=$(defaults ${param})


    if [[ -z "${USE_DEFAULTS}" ]]; then
        if [[ $param = *"password"* ]]; then
            read -s -p "${param_descriptions[${param}]} [${param_default}]: " param_input
            echo
        else
            read -p "${param_descriptions[${param}]} [${param_default}]: " param_input
        fi
    fi

    if [[ -z "${param_input}" ]]; then
        params[${param}]="${param_default}"
    else
        params[${param}]="${param_input}"
    fi
done

if [[ ${params["secondary_volume_type"]} != "skip" ]]; then
    encryption_keyfile="/root/tmp_encryption_keyfile"
    echo ">: Creating temporary encryption keyfile for secondary volume: [${encryption_keyfile}]..."
    sudo touch ${encryption_keyfile}
    sudo chown root:root ${encryption_keyfile}
    sudo chmod 0400 ${encryption_keyfile}
    echo -n "${params["encryption_password"]}" | sudo dd of=${encryption_keyfile} status=none
fi

ubuntu_codename=$(grep -ioP '^UBUNTU_CODENAME=\K.+' /etc/os-release)

ansible-playbook \
    provision.yml \
    --ask-become-pass \
    --extra-vars "target_user=${params['target_user']} \
                  target_user_full_name=${params['target_user_full_name']} \
                  nas_name=${params["nas_name"]} \
                  nas_hostname=${params["nas_hostname"]} \
                  nas_mount_target=${params["nas_mount_target"]} \
                  cifs_user=${params["cifs_user"]} \
                  secondary_volume_type=${params["secondary_volume_type"]} \
                  secondary_volume_name=${params["secondary_volume_name"]} \
                  secondary_volume_partition=${params["secondary_volume_partition"]} \
                  encryption_keyfile=${encryption_keyfile} \
                  ubuntu_codename=${ubuntu_codename}"

if [[ ${params["secondary_volume_type"]} != "skip" ]]; then
    echo ">: Removing temporary encryption keyfile for secondary volume: [${encryption_keyfile}]..."
    sudo shred -u -f ${encryption_keyfile} 2> /dev/null
fi
