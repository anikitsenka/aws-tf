import os
import re
import aioboto3
import asyncio
import configparser


# Extract bucket names from environment variables to the list
BUCKET_ARNS = os.environ["BUCKET_ARNS"].split(',')
# Regex pattern to match "data-N.ini" where N is a number
FILE_PATTERN = re.compile(r"^data-\d+\.ini$")
# DynamoDB parameters
HOST_PATTERN = r'(\d+)$'
ODD_TABLE = "odd_table"
EVEN_TABLE = "even_table"

def extract_bucket_names(arns: list) -> list:
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

async def write_to_dynamodb(dynamodb_client, item):
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

async def parse_database_host(s3_client, bucket, key):
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

async def list_and_process_bucket(bucket_name, session):
    results = []
    async with session.client('s3') as s3, session.client('dynamodb') as dynamodb:
        paginator = s3.get_paginator('list_objects_v2')
        async for page in paginator.paginate(Bucket=bucket_name):
            for obj in page.get('Contents', []):
                key = obj['Key']
                if FILE_PATTERN.match(key.split('/')[-1]):
                    datetime = obj['LastModified'].astimezone().isoformat()
                    result = await parse_database_host(s3, bucket_name, key)
                    result["datetime"] = datetime
                    results.append(result)
                    for result in results:
                        if "host" in result:
                            result["put_status"] = "tried"  # debug
                            write_result = await write_to_dynamodb(dynamodb, result)
                            result["dynamodb_status"] = write_result
                            if 'error' in write_result:
                                result["reported"] = "true"
                                result["error"] = result["dynamodb_status"]["error"]
                        # SNS
                        else:
                            result["put_status"] = "no_host" # debug
                            report = {}
                            # if 'dynamodb_status' in result and 'error' in result["dynamodb_status"]:
                                
                    # if "host" in results:
                    #     results["put_status"] = "tried"
                    #     write_result = await write_to_dynamodb(dynamodb, results)
                    #     results["dynamodb_status"] = write_result
    return results

async def process_buckets(bucket_names):
    session = aioboto3.Session()
    tasks = [list_and_process_bucket(bucket, session) for bucket in bucket_names]
    all_results = await asyncio.gather(*tasks)
    all_results.append(bucket_names) # debug
    return [item for sublist in all_results for item in sublist]

def lambda_handler(event, context):
    """
    """
    bucket_names = extract_bucket_names(BUCKET_ARNS)
    if not bucket_names:
        return {
            "statusCode": 400,
            "body": "Missing 'buckets' list in event"
        }

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    results = loop.run_until_complete(process_buckets(bucket_names))

    return {
        "statusCode": 200,
        "body": results
    }
