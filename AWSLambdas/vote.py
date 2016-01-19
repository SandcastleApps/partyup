"""
    Watch Votes stream and update Sample ups and downs
"""

import json
import boto3
import time
import decimal
from boto3.dynamodb.conditions import Key, Attr

def vote_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Samples')
    
    ratings = dict()

    for record in event['Records']:
        type = record['eventName']
        disposition = 0
        if type == "INSERT" or type == "MODIFY":
            disposition = int(record['dynamodb']['NewImage']['vote']['N'])
        if type == "MODIFY" or type == "REMOVE":
            disposition += -int(record['dynamodb']['OldImage']['vote']['N'])
        sample = record['dynamodb']['Keys']['sample']['B']
        ratings[sample] = ratings.get(sample, 0) + disposition



