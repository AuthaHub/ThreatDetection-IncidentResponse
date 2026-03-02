import boto3
import json
import os
from datetime import datetime

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ.get('DYNAMODB_TABLE')
    table = dynamodb.Table(table_name)
    
    try:
        # Log security event to DynamoDB
        item = {
            'event_id': context.aws_request_id,
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event.get('detail-type', 'Unknown'),
            'source': event.get('source', 'Unknown'),
            'detail': json.dumps(event.get('detail', {})),
            'region': event.get('region', 'Unknown'),
            'account': event.get('account', 'Unknown')
        }
        
        table.put_item(Item=item)
        print(f"Successfully logged event {context.aws_request_id} to DynamoDB")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'event_id': context.aws_request_id,
                'action': 'logged'
            })
        }
    except Exception as e:
        print(f"Error logging event: {str(e)}")
        raise