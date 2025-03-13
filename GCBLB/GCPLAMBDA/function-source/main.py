import json
import logging

def log_upload(event, context):
    file_name = event['name']
    bucket_name = event['bucket']
    logging.info(f"File uploaded: {file_name} in {bucket_name}")
