import boto3
from time import sleep

def lambda_handler(event, context):
  # Create boto3 session for support and IAM API. Suppot can only run in us-east-1
  session = boto3.session.Session()
  support_client = session.client(region_name='us-east-1',service_name='support')
  checks = support_client.describe_trusted_advisor_checks(language='en')
  output = {}
  users = []

  # Fetch the ID of the iam access key check in trusted advisor
  for check in checks['checks']:
    if check['name'] == 'IAM Access Key Rotation':
      check_id = check['id']

  # Refresh trusted advisor before fetching results
  response = support_client.refresh_trusted_advisor_check(checkId=check_id)

  while True:
    print('Fetching Trusted Advisor refresh status')
    refresh_status = support_client.describe_trusted_advisor_check_refresh_statuses(checkIds=[check_id])

    if refresh_status['statuses'][0]['status'] == 'success':
      print('Trusted advisor refresh completed. Fetching results.')
      # Fetch all the results of trusted advisor's check on iam access key
      results = support_client.describe_trusted_advisor_check_result(checkId=check_id,language='en')
      break
    elif refresh_status['statuses'][0]['status'] == 'abandoned':
      print('Trusted advisor failed to refresh. Create new request to refresh results')
      response = support_client.refresh_trusted_advisor_check(checkId=check_id)
      print('Sleeping 5 seconds')
      sleep(5)
    else:
      print('Trusted advisor still refreshing results. Sleeping 5 seconds')
      sleep(5)


  if results:
    output['check'] = True
    for result in results['result']['flaggedResources']:
      if result['status'] == 'warning':
        users.append(result['metadata'][1])
  else:
    output['check'] = False

  output['users'] = list(dict.fromkeys(users))

  return output
