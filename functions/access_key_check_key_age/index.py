import boto3
from datetime import datetime, timezone

def lambda_handler(event, context):
  user = event['username']
  iam_client = boto3.client('iam')
  access_key = iam_client.list_access_keys(UserName=user)
  output = {}
  output['key'] = []
  output['deactivate'] = False

  for key in access_key['AccessKeyMetadata']:
    create_date = key['CreateDate']
    current_date = datetime.now(timezone.utc)
    date_diff = current_date - create_date

    if date_diff.days > 120 and key['Status'] == 'Active':
      output['key'].append({ 'id': key['AccessKeyId'], 'age': date_diff.days})
      output['deactivate'] = True
    elif date_diff.days >= 90 and date_diff.days <= 120 and key['Status'] == 'Active':
        output['key'].append({ 'id': key['AccessKeyId'], 'age': date_diff.days})
    else:
      pass

  return output
