#!/bin/bash

# List of all endpoint IDs
endpoints=(
  305095785010167808
  931096133214666752
  6163153000312340480
  4092623071628754944
  8303488723220168704
  2147068032604700672
  3822407093986525184
  2261909823102648320
  1044249073852350464
  8533172304216064000
  7862830851086614528
  985834220091867136
  530970657727447040
  5597520238519255040
  459757488619651072
  8476164825339133952
  2481873721309003776
)

for endpoint_id in "${endpoints[@]}"; do
  echo "Checking endpoint $endpoint_id..."
  
  # Get deployed model IDs
  model_ids=$(gcloud ai endpoints describe $endpoint_id --region=us-central1 --project=gen-lang-client-0477203387 2>&1 | grep "^  id: '" | sed "s/.*id: '//" | sed "s/'//")
  
  if [ ! -z "$model_ids" ]; then
    for model_id in $model_ids; do
      echo "  Undeploying model $model_id from endpoint $endpoint_id"
      gcloud ai endpoints undeploy-model $endpoint_id --deployed-model-id=$model_id --region=us-central1 --project=gen-lang-client-0477203387 --quiet
      echo "  Waiting for operation to complete..."
      sleep 5
    done
  else
    echo "  No models deployed on this endpoint"
  fi
done

echo "All models undeployed!"