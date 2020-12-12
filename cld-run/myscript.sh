#!/bin/bash

echo "VM_NAME=$VM_NAME"
echo "VM_ZONE=$VM_ZONE"
echo "VM_PROJECT=$VM_PROJECT"

gcloud config set project $VM_PROJECT

OUTPUT=$(gcloud compute instances add-metadata $VM_NAME --zone=$VM_ZONE  --metadata=startup-script-url="gs://mybucket/my_script.sh" 2>&1)
echo $OUTPUT

if echo $OUTPUT | grep -q 'Updated'; then

    echo "First run on this VM. Running script"

    gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --quiet

    gcloud compute ssh $VM_NAME --zone=$VM_ZONE --command='sudo apt-get install -y nginx' \
    --tunnel-through-iap --quiet \

    # TODO - CLEAN UP
else
    echo "Already ran. Exiting"
fi