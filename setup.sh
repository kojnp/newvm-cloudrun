#!/bin/bash

# bash -v setup.sh  ORG_NAME="abcd.com" PROJECT_ID="xxxxxx"
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   
    case "$KEY" in
            ORG_NAME)           ORG_NAME=${VALUE} ;;
            PROJECT_ID)         PROJECT_ID=${VALUE} ;;  
            *)   
    esac    
done

set -u
: "$ORG_NAME"
: "$PROJECT_ID"

gcloud config set project $PROJECT_ID

export ORG_FULL_ID=$(gcloud organizations describe $ORG_NAME --format='value(name)')
export ORG_ID=${ORG_FULL_ID##*/}

export LOCATION=us-central1
export IMAGE_NAME=new-vm-container2
export CLOUD_RUN_SERVICE_NAME=new-vm-service2
export CLOUD_RUN_SA=new-vm-cloud-run-sa2
export CLOUD_RUN_INVOKER_SA=new-vm-cloud-run-invoker-sa2
export EVENTARC_TRIGGER_NAME=pubsub-trigger2
export LOGGING_SINK_NAME=new-vm-new-format-sink2

gcloud iam service-accounts create $CLOUD_RUN_SA
export SA_ORG_IAM_GRANT_CMD_PREFIX="gcloud organizations add-iam-policy-binding  $ORG_ID --member='serviceAccount:$CLOUD_RUN_SA@$PROJECT_ID.iam.gserviceaccount.com'"
eval "$SA_ORG_IAM_GRANT_CMD_PREFIX --role='roles/compute.admin'"
eval "$SA_ORG_IAM_GRANT_CMD_PREFIX --role='roles/iap.tunnelResourceAccessor'"
eval "$SA_ORG_IAM_GRANT_CMD_PREFIX --role='roles/resourcemanager.projectIamAdmin'"
eval "$SA_ORG_IAM_GRANT_CMD_PREFIX --role='roles/run.serviceAgent'"

cd cld-run

gcloud builds submit \
  --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
  --platform managed \
  --region $LOCATION \
  --service-account=$CLOUD_RUN_SA@$PROJECT_ID.iam.gserviceaccount.com \
  --no-allow-unauthenticated

gcloud iam service-accounts create $CLOUD_RUN_INVOKER_SA

gcloud run services add-iam-policy-binding $CLOUD_RUN_SERVICE_NAME \
  --member="serviceAccount:$CLOUD_RUN_INVOKER_SA@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker" --platform=managed --region=$LOCATION

gcloud beta eventarc triggers create $EVENTARC_TRIGGER_NAME \
  --location=$LOCATION \
  --destination-run-service $CLOUD_RUN_SERVICE_NAME \
  --matching-criteria "type=google.cloud.pubsub.topic.v1.messagePublished" \
  --service-account=$CLOUD_RUN_INVOKER_SA@$PROJECT_ID.iam.gserviceaccount.com

export EVENTARC_TOPIC=$(gcloud beta eventarc triggers describe $EVENTARC_TRIGGER_NAME --location=$LOCATION --format='value(transport.pubsub.topic)')

gcloud logging sinks create $LOGGING_SINK_NAME pubsub.googleapis.com/$EVENTARC_TOPIC --project=$PROJECT_ID --log-filter='resource.type="gce_instance" AND protoPayload.methodName =~ "compute.instances.insert"'

export WRITER_IDENTITY=$(gcloud logging sinks describe $LOGGING_SINK_NAME --format='value(writerIdentity)')

gcloud pubsub topics add-iam-policy-binding $EVENTARC_TOPIC  --member="$WRITER_IDENTITY" --role='roles/pubsub.publisher'
