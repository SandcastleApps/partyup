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
logger.setLevel(logging.ERROR)

def purge_vote(vote, votes_batch):
    votes_batch.delete_item(Key={'sample' : vote['sample'], 'user': vote['user']})

def purge_sample(sample, vote_table, samples_batch, votes_batch):
    samples_batch.delete_item(Key={'event' : sample['event'], 'id': sample['id']})
    sample_identity =  Binary(sample['id'].value + bytearray(sample['event'], "utf_8"))
    sample_key = Key('sample').eq(sample_identity)

    response = vote_table.query(KeyConditionExpression=sample_key)

    for item in response['Items']:
        purge_vote(item, votes_batch)

        while 'LastEvaluatedKey' in response:
            response = query(KeyConditionExpression=sample_key, ExclusiveStartKey=response['LastEvaluatedKey'])

            for item in response['Items']:
                purge_vote(item, votes_batch)

def purge_handler(event, context):
    dynamodb = boto3.resource('dynamodb')

    sample_table = dynamodb.Table('Samples')
    vote_table = dynamodb.Table('Votes')

    filter = Attr('time').lte(Decimal(time.time()-172800)) & Attr('prefix').not_exists()

    with sample_table.batch_writer() as samples_batch, vote_table.batch_writer() as votes_batch:
        response = sample_table.scan(
            FilterExpression=filter
        )

        for item in response['Items']:
            purge_sample(item, vote_table, samples_batch, votes_batch)

        while 'LastEvaluatedKey' in response:
            response = scan(
                FilterExpression=filter,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )

            for item in response['Items']:
                purge_sample(item, vote_table, samples_batch, votes_batch)
