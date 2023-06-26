import json
import boto3
import os


BUCKET_NAME = os.environ.get("BUCKET_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")

EXPIRATION_TIME = 600 # Time in seconds for the presigned URL to remain valid

def get_download_url(namespace, module, provider, version):
    dynamodb_client = boto3.client("dynamodb")
    response = dynamodb_client.get_item(
        TableName=TABLE_NAME,
        Key={
            'Id': {'S': f"{namespace}/{module}/{provider}"},
            'Version': {'S': version}
        }
    )
    return response['Item']['Source']['S']

def create_presigned_url( object_name):
    s3_client = boto3.client('s3',config=boto3.session.Config(signature_version='s3v4',))
    return s3_client.generate_presigned_url(
        'get_object',
        Params={
            'Bucket': BUCKET_NAME,
            'Key': object_name
        },
        ExpiresIn=EXPIRATION_TIME)
    
    
def lambda_handler(event, context):
    status_code = 200
    response_message = ""

    # see https://developer.hashicorp.com/terraform/language/modules/sources#http-urls
    x_terraform_get = ""

    # get api gateway path parameter
    path_param = event['pathParameters']
    namespace = path_param['namespace']
    provider = path_param['provider']
    module = path_param['module']
    version = path_param['version']

    try:
        source = get_download_url(namespace=namespace, module=module, provider=provider, version=version)
    
        # if we are in the bucket associated with the registry, we can use presigned url
        if source.startswith(f"s3::https://{BUCKET_NAME}"):
            # remove bucket url part
            source = source[source.index(".com/") + 5:]
            # presign
            source = create_presigned_url(object_name=source)  

        x_terraform_get = source
        response_message = {
            'version': version,
            'source': source
        }
    except Exception as e:
        status_code = 500
        response_message  = str(e)

    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'X-Terraform-Get': x_terraform_get
        },
        'body': json.dumps(response_message)
    }