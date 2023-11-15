import boto3

def lambda_handler(event, contex):
  user = event['username']
  access_keys = event['check']['key']
  iam_client = boto3.client('iam')

  for access_key in access_keys:
    if access_key['age'] > 120:
      response = iam_client.update_access_key(AccessKeyId=access_key['id'], UserName=user, Status='Inactive')
    else:
      pass

  return response
