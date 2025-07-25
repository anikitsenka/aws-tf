import asyncio
import configparser
import os
import re
from typing import Any

import aioboto3
import aiobotocore
import boto3

# Extract bucket names from environment variable to the list
BUCKET_ARNS = os.environ["BUCKET_ARNS"].split(',')
# Extract SNS topic ARN
SNS_ARN = os.environ['SNS_TOPIC_ARN']
# Define SNS client
SNS_CLIENT = boto3.client('sns')
# Regex pattern to match "data-N.ini" where N is a number
FILE_PATTERN = re.compile(r"^data-\d+\.ini$")
# DynamoDB parameters
HOST_PATTERN = r'(\d+)$'
ODD_TABLE = "odd_table"
EVEN_TABLE = "even_table"


def send_report_email(data: str) -> dict:
    try:
        response = SNS_CLIENT.publish(
            TopicArn=SNS_ARN,
            Message=str(data),
            Subject=f'Lambda Notification from {SNS_ARN}'
        )
        return {
            'statusCode': 200,
            'body': f'Report sent to SNS: {response["MessageId"]}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': {
                'message': 'Error publishing report',
                'error': str(e),
            }
        }

def extract_bucket_names(arns: list[str]) -> list[str]:
    bucket_names = []
    for arn in arns:
        parts = arn.split(":")
        if len(parts) == 6 and parts[2] == "s3":
            # Remove leading slashes (in case it's a key or object ARN)
            bucket_part = parts[5].lstrip("/")
            # In case it's an object ARN (like arn:aws:s3:::bucket-name/key), split at the first slash
            bucket_name = bucket_part.split("/")[0]
            bucket_names.append(bucket_name)
    return bucket_names

def get_host_number_type(host: str) -> str | None:
    """
    Returns "odd", "even", or None depending on the last digit in the host.
    """
    if not host:
        return None
    match = re.search(HOST_PATTERN, host)
    if match:
        last_digit = int(match.group(1)[-1])
        return "odd" if last_digit % 2 == 1 else "even"
    return None

async def write_to_dynamodb(dynamodb_client: aiobotocore.client.BaseClient, item: dict) -> dict:
    host_type = get_host_number_type(item.get("host"))
    if host_type == "odd":
        table_name = ODD_TABLE
    elif host_type == "even":
        table_name = EVEN_TABLE
    else:
        return {"status": "error", "error": "Host does not end with a number"}

    try:
        await dynamodb_client.put_item(
            TableName=table_name,
            Item={
                'bucket_name': {'S': item['bucket']},
                'key': {'S': item['key']},
                'host': {'S': item['host']},
                'datetime': {'S': item['datetime']},
            }
        )
        return {"status": "success", "table": table_name}
    except Exception as e:
        return {"status": "error", "table": table_name, "error": str(e)}

async def parse_database_host(s3_client: aiobotocore.client.BaseClient, bucket: str, key: str) -> dict:
    try:
        response = await s3_client.get_object(Bucket=bucket, Key=key)
        content = await response['Body'].read()

        parser = configparser.ConfigParser()
        parser.read_string(content.decode('utf-8'))

        if parser.has_section("Database") and parser.has_option("Database", "Host"):
            host_value = parser.get("Database", "Host")
            return {
                "bucket": bucket,
                "key": key,
                "host": host_value
            }
        else:
            return {
                "bucket": bucket,
                "key": key,
                "error": "'Host' not found in [Database] section"
            }

    except Exception as e:
        return {
            "bucket": bucket,
            "key": key,
            "error": f"Parsing error: {str(e)}"
        }

async def list_and_process_bucket(bucket_name: str, session: aioboto3.session.Session) -> list[dict]:
    results = []
    reports = []
    async with session.client('s3') as s3, session.client('dynamodb') as dynamodb:
        paginator = s3.get_paginator('list_objects_v2')
        async for page in paginator.paginate(Bucket=bucket_name):
            for obj in page.get('Contents', []):
                key = obj['Key']
                if FILE_PATTERN.match(key.split('/')[-1]):
                    datetime = obj['LastModified'].astimezone().isoformat()
                    result = await parse_database_host(s3, bucket_name, key)
                    result["s3_class"] = str(type(s3))
                    result["datetime"] = datetime
                    results.append(result)
                    for result in results:
                        if "host" in result:
                            result["put_status"] = "tried"  # debug
                            write_result = await write_to_dynamodb(dynamodb, result)
                            result["dynamodb_status"] = write_result
                            result["dynamodb_class"] = str(type(dynamodb))
                            if "error" in write_result:
                                result["reported"] = "true"
                                result["error"] = result["dynamodb_status"]["error"]
                        # SNS
                        if "error" in result:
                            report = {}
                            report["bucket"] = result["bucket"]
                            report["key"] = result["key"]
                            report["error"] = result["error"]
                            reports.append(report)
                        # else:
                        #     result["put_status"] = "no_host" # debug
                        #     report = {}
                            # if 'dynamodb_status' in result and 'error' in result["dynamodb_status"]:
                                
                    # if "host" in results:
                    #     results["put_status"] = "tried"
                    #     write_result = await write_to_dynamodb(dynamodb, results)
                    #     results["dynamodb_status"] = write_result
    publish_results = send_report_email(str(reports))
    results.append(publish_results)
    return results

async def process_buckets(bucket_names: list[str]):
    session = aioboto3.Session()
    tasks = [list_and_process_bucket(bucket, session) for bucket in bucket_names]
    all_results = await asyncio.gather(*tasks)
    # all_results.append(bucket_names) # debug
    # all_results.append([str(type(session))]) # debug
    return [item for sublist in all_results for item in sublist]

def lambda_handler(event, context):
    """
    """
    bucket_names = extract_bucket_names(BUCKET_ARNS)
    # if not bucket_names:
    #     return {
    #         "statusCode": 400,
    #         "body": "Missing 'buckets' list in event"
    #     }

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    results = loop.run_until_complete(process_buckets(bucket_names))

    return {
        "statusCode": 200,
        "body": results
    }
