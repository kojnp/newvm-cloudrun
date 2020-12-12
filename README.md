# New VM -> script install

```diff
- NOT PRODUCTION READY
- NO RESPONSIBLITY
- FOR DEMO PURPOSES ONLY
```

## setup & test

```sh
bash setup.sh ORG_NAME="abcd.com" PROJECT_ID="xyz"

gcloud compute instances create test-vm-pubsub-instance --machine-type=f1-micro --zone=us-central1-b --preemptible --no-restart-on-failure --maintenance-policy=terminate --no-address
```

In Console , go to Logging -> 
type in the query:
`resource.type=cloud_run_revision`
and click on "Run Query"