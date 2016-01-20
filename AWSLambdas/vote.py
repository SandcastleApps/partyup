"""
    Watch Votes stream and update Sample ups and downs
    """

import json
import boto3
import time
import decimal
import base64
from boto3.dynamodb.conditions import Key, Attr
from decimal import Decimal

def consolidate_disposition(disposition_map, records):
    for record in records:
        type = record['eventName']
        disposition = 0
        if type == "INSERT" or type == "MODIFY":
            disposition = int(record['dynamodb']['NewImage']['vote']['N'])
        if type == "MODIFY" or type == "REMOVE":
            disposition += -int(record['dynamodb']['OldImage']['vote']['N'])
        sample = record['dynamodb']['Keys']['sample']['B']
        disposition_map[sample] = disposition_map.get(sample, 0) + disposition


def vote_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Samples')
    
    ratings = dict()
    consolidate_disposition(ratings, event['Records'])
    
    for (sample, vote) in ratings.iteritems():
        ident = "b74z7/Q1TdqouIVyIXp+DQU=" """sample[0:19]"""
        event = "ChIJ1QvXETf7Z0sRBkcNQqQ89ag" """base64.standard_b64decode(sample[18:])"""
        up = 1
        down = -1
        table.update_item(
                          Key={'event': event, 'id': ident},
                          UpdateExpression='ADD ups :up, downs :down',
                          ExpressionAttributeValues={':up':{'N': up}, ':down':{'N': down}}
                          )