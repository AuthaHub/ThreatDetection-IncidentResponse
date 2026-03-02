import boto3
import json
from datetime import datetime

def handler(event, context):
    ec2 = boto3.client('ec2')
    
    detail = event.get('detail', {})
    instance_id = detail.get('resource', {}).get('instanceDetails', {}).get('instanceId')
    
    if not instance_id:
        print("No instance ID found in event")
        return {'statusCode': 400, 'body': 'No instance ID found'}
    
    try:
        # Get all volumes attached to the instance
        response = ec2.describe_instances(InstanceIds=[instance_id])
        volumes = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                for mapping in instance.get('BlockDeviceMappings', []):
                    volumes.append(mapping['Ebs']['VolumeId'])
        
        # Create forensic snapshots
        snapshots = []
        for volume_id in volumes:
            snapshot = ec2.create_snapshot(
                VolumeId=volume_id,
                Description=f'Forensic snapshot of {volume_id} from compromised instance {instance_id} at {datetime.utcnow().isoformat()}'
            )
            snapshots.append(snapshot['SnapshotId'])
            print(f"Created forensic snapshot {snapshot['SnapshotId']} for volume {volume_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'instance_id': instance_id,
                'snapshots': snapshots,
                'action': 'snapshots_created'
            })
        }
    except Exception as e:
        print(f"Error creating snapshots: {str(e)}")
        raise