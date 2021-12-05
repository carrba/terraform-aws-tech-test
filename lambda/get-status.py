import boto3
import datetime
from decimal import Decimal

def getttl():
    addday = datetime.timedelta(days=1)
    myttl = datetime.datetime.now()
    myttl += addday
    epochtime = myttl.timestamp()
    return epochtime

def gettime():
    myttl = datetime.datetime.now()
    epochtime = myttl.timestamp()
    return epochtime

client = boto3.client('ec2')

AWS_REGION = "eu-west-1"
EC2_RESOURCE = boto3.resource('ec2', region_name=AWS_REGION)
OWNER = 'Brian Carr'

instances = EC2_RESOURCE.instances.filter(
    Filters=[
        {
            'Name': 'tag:Owner',
            'Values': [
                OWNER
            ]
        }
    ]
)

myepochtime = getttl()
mytime = gettime()

dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('bc-ec2-state')

for instance in instances:
    # print(f'Instance ID: {instance.id}')
    # print(f'state: {instance.state["Name"]}' )
    # print(f'ttl: {myepochtime}')

    table.put_item(Item={'id': str(instance.id), 'state': str(instance.state["Name"]), 'ttl': Decimal(myepochtime), 'CreationTime': Decimal(mytime)  })
