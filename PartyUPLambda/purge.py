"""
Scan through the Samples table for oldish entries and remove them.
"""

import json
import boto3
import time
import decimal
from boto3.dynamodb.conditions import Key, Attr

def purge_item(item, batch):
    response = batch.delete_item(
        Key={
            'event' : item['event'],
            'id': item['id']
        }
    )

def purge_handler(event, context):
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('Samples')
    filter = Attr('time').lte(decimal.Decimal(time.time()-43200))

    with table.batch_writer() as batch:
        response = table.scan(
            FilterExpression=filter
        )

        for item in response['Items']:
            purge_item(item, batch)

        while 'LastEvaluatedKey' in response:
            response = scan(
                FilterExpression=filter,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )

            for item in response['Items']:
                purge_item(item, batch)
