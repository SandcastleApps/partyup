"""
Scan through the Samples table for oldish entries and remove them and the video file
associated with the entery.
"""

import json
import boto3
import time
import decimal
import uuid
from boto3.dynamodb.conditions import Key, Attr

def purge_item(item, batch, s3):
    id_bytes = item['id'].value
    id_unique = str(uuid.UUID(bytes=id_bytes[0:16])).upper()
    id_count = ord(id_bytes[16])

    response = batch.delete_item(
        Key={
            'event' : item['event'],
            'id': item['id']
        }
    )

    video = s3.Object('com.sandcastleapps.partyup', 'media/' + id_unique + str(id_count) + '.mp4')
    video.delete()

def purge_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.resource('s3')

    table = dynamodb.Table('Samples')
    filter = Attr('time').lte(decimal.Decimal(time.time()))

    with table.batch_writer() as batch:
        response = table.scan(
            FilterExpression=filter
        )

        for item in response['Items']:
            purge_item(item, batch, s3)

        while 'LastEvaluatedKey' in response:
            response = scan(
                FilterExpression=filter,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )

            for item in response['Items']:
                purge_item(item, batch, s3)
