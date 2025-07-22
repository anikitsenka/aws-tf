import boto3
import os

sns_arn = os.environ['SNS_TOPIC_ARN']
sns = boto3.client('sns')

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    try:
        response = s3.list_buckets()
        bucket_names = [bucket['Name'] for bucket in response.get('Buckets', [])]
        response = sns.publish(
            TopicArn=sns_arn,
            Message=str(bucket_names),
            Subject='Lambda Notification'
        )
        return {
            'statusCode': 200,
            'body': f'Message sent to SNS: {response["MessageId"]}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': {
                'message': 'Error publishing S3 bucket list',
                'error': str(e),
            }
        }
