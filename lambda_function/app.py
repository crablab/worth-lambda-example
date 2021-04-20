import json

def example_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Hello World!')
    }