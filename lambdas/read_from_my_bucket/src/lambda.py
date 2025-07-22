import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = 'nikitsenka-readonly-storage'
    file_path = 'response.json'

    try:
        response = s3.get_object(Bucket=bucket_name, Key=file_path)
        content = response['Body'].read().decode('utf-8')
        data = json.loads(content)

        return {
            'statusCode': 200,
            'body': json.dumps(data)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
