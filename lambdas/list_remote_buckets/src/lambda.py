import boto3

# Role ARN from the remote AWS account
REMOTE_ROLE_ARN = 'arn:aws:iam::880522701894:role/andrei_test_role_s3_read'
SESSION_NAME = 'crossAccountS3ListSession'

def lambda_handler(event, context):
    try:
        sts_client = boto3.client('sts')
        assumed_role = sts_client.assume_role(
            RoleArn=REMOTE_ROLE_ARN,
            RoleSessionName=SESSION_NAME
        )

        credentials = assumed_role['Credentials']

        # Step 2: Use assumed role credentials to create S3 client
        s3_client = boto3.client(
            's3',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
        )

        # Step 3: List buckets in the remote account
        response = s3_client.list_buckets()
        bucket_names = [bucket['Name'] for bucket in response.get('Buckets', [])]

        return {
            'statusCode': 200,
            'body': bucket_names,
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': {
                'message': 'Error retrieving S3 bucket list',
                'error': str(e),
            }
        }
