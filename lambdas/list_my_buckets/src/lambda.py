import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    try:
        response = s3.list_buckets()
        bucket_names = [bucket['Name'] for bucket in response.get('Buckets', [])]
        return {
            'statusCode': 200,
            'body': {
                'message': 'Successfully retrieved S3 bucket list',
                'buckets': bucket_names,
            }
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': {
                'message': 'Error retrieving S3 bucket list',
                'error': str(e),
            }
        }
