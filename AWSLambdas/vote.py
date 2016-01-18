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

    for record in event['Records']:
        print(record['dynamodb']['NewImage'])

