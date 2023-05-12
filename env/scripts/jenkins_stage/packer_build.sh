#!/bin/bash
set -e

ansible --version

# sts
sts_clean() {
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

sts() {
    sts_clean
    raw_output=$(aws sts assume-role --role-arn ${1} --role-session-name "packer" --region ${2})

    export AWS_ACCESS_KEY_ID=$(echo ${raw_output} | jq .Credentials.AccessKeyId | sed s/\"//g)
    export AWS_SECRET_ACCESS_KEY=$(echo ${raw_output} | jq .Credentials.SecretAccessKey | sed s/\"//g)
    export AWS_SESSION_TOKEN=$(echo ${raw_output} | jq .Credentials.SessionToken | sed s/\"//g)
}

# Switch to packer directory
echo ${WORKSPACE}
cd ${WORKSPACE}/packer

# Add custom time format
export TZ=Asia/Seoul
export BAKE_TIME=$(date '+%Y%m%d%H%M%S')
echo ${BAKE_TIME} >${WORKSPACE}/packer/bake_time.txt

# Generate SSH Key
ssh-keygen -N "" -f ${BUILD_TAG}

export repo=$(git config --get remote.origin.url | grep -o -E "/[A-Za-z0-9-]+\.git$" | sed "s/\///g" | sed "s/.git//g")

# Make ansible file of current version including remote roles
cd ..
mkdir ansible-origin
cp -r ./packer ./ansible-origin/
zip -r ansible.zip ./ansible-origin/*
mv ansible.zip ./packer
cd packer

packer --version

export USERDATA_PATH=userdata/userdata.sh
export USER=jenkins

arr=($(cat ../env/packer_regions | tr "," " "))

for region in "${arr[@]}"; do
    export ssh_username="ec2-user"
    # AMI_OWNER="137112412989"

    # Find public amazon-linux2 image (for old version )
    # export ami=$(aws ec2 describe-images --region ${region} --owners ${AMI_OWNER} --filters 'Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0.*.*-x86_64-gp2' 'Name=state,Values=available' | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')

    # Set features of public amazon-linux2 image
    export ami_owner="137112412989"
    export virtualization_type="hvm"
    export source_ami_name="amzn2-ami-kernel-5.10-hvm-2.0.*.*-x86_64-gp2"
    export root_device_type="ebs"

    export user_data_file="../env/scripts/user_data/ssh_port_change.sh"

    sts_clean
    sts "arn:aws:iam::123456789:role/media-platform-deployment-role" "${region}"

    echo assumed to ${AWS_ACCESS_KEY_ID}

    packer build -color=false \
        -var-file=../env/${region}.json \
        -var-file=./services/amazon-linux.json \
        -var ssh_key_inspec=${BUILD_TAG} \
        -var bake_time=${BAKE_TIME} \
        -var ami_owner=${ami_owner} \
        -var virtualization_type=${virtualization_type} \
        -var source_ami_name=${source_ami_name} \
        -var root_device_type=${root_device_type} \
        -var aws_region=${region} \
        -var user_data_file=${user_data_file} \
        -var ssh_username=${ssh_username} \
        ../env/packer.json &
done

for job in $(jobs -p); do
    wait ${job} || exit 1
done

echo "Packer done successfully"
