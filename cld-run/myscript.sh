#!/bin/bash

# TODO - fix for alpine / change OS
# alpine base image -> doesnt work. I wanted a random string to have at prefix at output to distinguish between concurrent runs
#apk add cat tr fold head
#GG=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)

#echo "${GG}|| VM_NAME=${VM_NAME}"
#echo "${GG}|| VM_ZONE=${VM_ZONE}"
#echo "${GG}|| VM_PROJECT=${VM_PROJECT}"
echo "VM_NAME=$VM_NAME"
echo "VM_ZONE=$VM_ZONE"
echo "VM_PROJECT=$VM_PROJECT"

gcloud config set project $VM_PROJECT

#OUTPUT=$(gcloud compute instances add-metadata $VM_NAME --zone=$VM_ZONE  --metadata=startup-script-url="gs://mybucket/my_script.sh" 2>&1)
#echo "$OUTPUT"
#gcloud auth list

#sometimes SSH fails first time (not authorized - bcs VM is probably not yet set up. 
# Solution: either comment below and attempt to install for the few duplicate events that are created OR do a sleep to allow the VM to complete setup
# I chose to comment) . This is not production ready.

#if echo $OUTPUT | grep -q 'Updated'; then

#    echo "${GG}|| First run on this VM. Running script"

    gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --quiet

    gcloud auth list
    #echo "${GG}"

    gcloud compute ssh $VM_NAME --zone=$VM_ZONE --command='sudo apt-get install -y nginx' \
    --tunnel-through-iap  --verbosity info #--quiet

    # TODO - CLEAN UP
#else
#    echo "Already ran. Exiting"
#fi