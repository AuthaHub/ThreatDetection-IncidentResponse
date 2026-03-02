import boto3
import json
import os

def handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Extract instance ID from GuardDuty finding via EventBridge
    detail = event.get('detail', {})
    instance_id = detail.get('resource', {}).get('instanceDetails', {}).get('instanceId')
    
    if not instance_id:
        print("No instance ID found in event")
        return {'statusCode': 400, 'body': 'No instance ID found'}
    
    # Create isolation security group
    vpc_id = detail.get('resource', {}).get('instanceDetails', {}).get('networkInterfaces', [{}])[0].get('vpcId')
    
    try:
        # Create empty security group to isolate instance
        sg = ec2.create_security_group(
            GroupName=f'ISOLATED-{instance_id}',
            Description=f'Isolation SG for compromised instance {instance_id}',
            VpcId=vpc_id
        )
        sg_id = sg['GroupId']
        
        # Modify instance to use isolation security group
        ec2.modify_instance_attribute(
            InstanceId=instance_id,
            Groups=[sg_id]
        )
        
        print(f"Successfully isolated instance {instance_id} with SG {sg_id}")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'instance_id': instance_id,
                'isolation_sg': sg_id,
                'action': 'isolated'
            })
        }
    except Exception as e:
        print(f"Error isolating instance: {str(e)}")
        raise