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

basic_bucket = 'com.sandcastleapps.partyup'
standard_lifetime = 172800
standard_prefix = 'media'
favorite_lifetime = 604800
favorite_prefix = 'favorite'
favorite_count_max = 3

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

    video = s3.Object(basic_bucket, '/' + favorite_prefix + '/' + id_unique + str(id_count) + '.mp4')
    video.copy_from(CopySource=basic_bucket + '/' + standard_prefix + '/' + id_unique + str(id_count) + '.mp4', StorageClass='REDUCED_REDUNDANCY')
    samples_batch.update_item(Key={'event' : sample['event'], 'id': sample['id']}, UpdateExpression="set prefix=:f", ExpressionAttributeValues={':f': favorite_prefix})

def process_sample(sample, vote_table, samples_batch, votes_batch, s3, candidates):
    kept = False

    if sample['time'] <= time.time()-favorite_lifetime:
        rating = sample['ups'] - sample['downs']
        if rating >= 0:
            candidate_list = candidates.get(sample['event'])
            
            for i, v in enumerate(candidate_list.):


    if !kept:
        purge_sample(sample, vote_table, samples_batch, votes_batch)


def purge_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.resource('s3')

    sample_table = dynamodb.Table('Samples')
    vote_table = dynamodb.Table('Votes')

    candidates = dict()

    filter = (Attr('time').lte(Decimal(time.time()-standard_lifetime)) & Attr('prefix').not_exists()) | Attr('prefix').eq(favorite_prefix)

    with sample_table.batch_writer() as samples_batch, vote_table.batch_writer() as votes_batch:
        response = sample_table.scan(
            FilterExpression=filter
        )

        for item in response['Items']:
            process_sample(item, vote_table, samples_batch, votes_batch, s3, candidates)

        while 'LastEvaluatedKey' in response:
            response = scan(
                FilterExpression=filter,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )

            for item in response['Items']:
                process_sample(item, vote_table, samples_batch, votes_batch, s3, candidates)

        for venue_candidates in candidates.itervalues():
            for candidate in venue_candidates.itervalues():
                favorite_sample(candidate, samples_batch, s3)
