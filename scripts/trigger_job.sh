#!/bin/bash
# Wait for crawler to complete and trigger Glue job

CRAWLER_NAME=$1
JOB_NAME=$2
REGION=$3
PROFILE=$4

echo "Waiting for crawler '$CRAWLER_NAME' to complete..."

for i in {1..30}; do
  STATUS=$(aws glue get-crawler --name "$CRAWLER_NAME" --region "$REGION" --profile "$PROFILE" --query 'Crawler.State' --output text 2>/dev/null)

  if [ "$STATUS" = "READY" ]; then
    echo "Crawler is ready. Starting Glue job '$JOB_NAME'..."
    aws glue start-job-run --job-name "$JOB_NAME" --region "$REGION" --profile "$PROFILE" || true
    exit 0
  fi

  echo "Waiting for crawler to complete... (attempt $i/30, status: $STATUS)"
  sleep 10
done

echo "Timeout waiting for crawler to complete"
exit 1
