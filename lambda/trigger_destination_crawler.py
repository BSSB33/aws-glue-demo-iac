"""
Lambda Function: Auto-trigger Destination Crawler
Triggered by EventBridge when Glue job completes successfully.
"""

import json
import boto3
import os

glue_client = boto3.client('glue')

def lambda_handler(event, context):
    """
    Triggered when Glue job state changes to SUCCEEDED.
    Starts the destination crawler to catalog transformed Parquet files.
    """

    print(f"Event received: {json.dumps(event)}")

    # Get crawler name from environment variable
    crawler_name = os.environ.get('DESTINATION_CRAWLER_NAME')

    if not crawler_name:
        raise ValueError("DESTINATION_CRAWLER_NAME environment variable not set")

    # Extract job details from event
    job_name = event['detail']['jobName']
    job_run_id = event['detail']['jobRunId']
    job_state = event['detail']['state']

    print(f"Glue job '{job_name}' (run: {job_run_id}) completed with state: {job_state}")

    # Only trigger crawler if job succeeded
    if job_state == 'SUCCEEDED':
        try:
            print(f"Starting destination crawler: {crawler_name}")

            response = glue_client.start_crawler(Name=crawler_name)

            print(f"Crawler started successfully: {response}")

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'Destination crawler {crawler_name} started successfully',
                    'job_name': job_name,
                    'job_run_id': job_run_id
                })
            }

        except glue_client.exceptions.CrawlerRunningException:
            print(f"Crawler {crawler_name} is already running, skipping")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'Crawler {crawler_name} already running',
                    'job_name': job_name
                })
            }

        except Exception as e:
            print(f"Error starting crawler: {str(e)}")
            raise
    else:
        print(f"Job state is {job_state}, not starting crawler")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Job state is {job_state}, crawler not triggered'
            })
        }
