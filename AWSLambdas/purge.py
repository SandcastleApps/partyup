"""
Scan through the Samples table for oldish items with no prefix attibute and remove them.
"""
import logging
import json
import boto3
import time
from decimal import Decimal
from boto3.dynamodb.types import Binary
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def purge_sample(sample, vote_table, samples_batch, votes_batch):
    samples_batch.delete_item(Key={'event' : sample['event'], 'id': sample['id']})
    sample_identity =  Binary(sample['id'].value + bytearray(sample['event'], "utf_8"))
    sample_key = Key('sample').eq(sample_identity)

    response = vote_table.query(KeyConditionExpression=sample_key)

    for item in response['Items']:
        votes_batch.delete_item(Key={'sample' : item['sample'], 'user': item['user']})

        while 'LastEvaluatedKey' in response:
            response = query(KeyConditionExpression=sample_key, ExclusiveStartKey=response['LastEvaluatedKey'])

            for item in response['Items']:
                votes_batch.delete_item(Key={'sample' : item['sample'], 'user': item['user']})

def favorite_sample(sample, samples_batch, s3):
    id_bytes = sample['id'].value
    id_unique = str(uuid.UUID(bytes=id_bytes[0:16])).upper()
    id_count = ord(id_bytes[16])

    video = s3.Object('com.sandcastleapps.partyup', 'favorites/' + id_unique + str(id_count) + '.mp4')
    video.copy_from(CopySource='com.sandcastleapps.partyup/media/' + id_unique + str(id_count) + '.mp4', StorageClass='REDUCED_REDUNDANCY')
    samples_batch.update_item(Key={'event' : sample['event'], 'id': sample['id']}, UpdateExpression='set prefix=favorites')

def process_sample(sample, vote_table, samples_batch, votes_batch, s3):


def purge_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.resource('s3')

    sample_table = dynamodb.Table('Samples')
    vote_table = dynamodb.Table('Votes')

    filter = (Attr('time').lte(Decimal(time.time()-172800)) & Attr('prefix').not_exists()) | (Attr('time').lte(Decimal(time.time()-))

    with sample_table.batch_writer() as samples_batch, vote_table.batch_writer() as votes_batch:
        response = sample_table.scan(
            FilterExpression=filter
        )

        for item in response['Items']:
            process_sample(item, vote_table, samples_batch, votes_batch, s3)

        while 'LastEvaluatedKey' in response:
            response = scan(
                FilterExpression=filter,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )

            for item in response['Items']:
                process_sample(item, vote_table, samples_batch, votes_batch, s3)
