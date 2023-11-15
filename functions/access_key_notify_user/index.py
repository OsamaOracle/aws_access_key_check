import boto3
from os import getenv
from botocore.exceptions import ClientError

def get_user_email(username):
  iam_client = boto3.client('iam')
  user_tags = iam_client.list_user_tags(UserName=username)
  default_email = getenv('DEFAULT_EMAIL')

  for tag in user_tags['Tags']:
    if tag['Key'] == 'Email':
      email = tag['Value']
      break
    else:
      email = default_email

  return email

def lambda_handler(event, context):
  sender = "Tutuka AWS Notifications <aws-notifications@ops.tutuka.cloud>"
  region = getenv('REGION')
  charset = "UTF-8"
  ses_client = boto3.client('ses',region_name=region)
  recipient = get_user_email(event['username'])
  subject = "Expiring AWS Access Keys"
  deactivated_key_table = ''
  rotate_key_table = ''

  for key in event['check']['key']:
    if key['age'] > 120:
      deactivated_key_table += '''
      <tr>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td style="background-color: #CD5C5C"><b>Deactivated</b></td>
      </tr>'''.format(event['username'], key['id'], key['age'])

    if key['age'] <= 120:
      rotate_key_table += '''
      <tr>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td style="background-color: #FFD700"><b>Warning</b></td>
      </tr>'''.format(event['username'], key['id'], key['age'])

# The HTML body of the email.
  body_html = """<html>
  <head></head>
  <body>
    Hi,
    <br></br>
    <p>
    This is an automated email from AWS. You are receiving this email because your AWS access keys are older than 90 days. Please take the necessary action to rotate these keys. An email notification will be sent to you everyday until the keys have been rotated. You will be given time to rotate your keys. Once the keys are older than 120 days, it will be deactivated automatically.
    </p>
    <p>
    You can refer to the documentation on <a href=https://paymentology.atlassian.net/wiki/spaces/TS/pages/2152169789/Rotating+AWS+Access+Key+and+Secret+Key>Rotating AWS Access Key and Secret Key</a>.
    <br>If you have further questions, kindly talk to Paymentology's DevOps team.</br>
    </p>
    <h2>AWS Access Keys</h2>
    <p>
      Please note that you are given a warning if the key is older than 90 days. The key will be deactivated after 120 days.
      <table border="1">
        <tr>
        <th>Username</th>
        <th>Key ID</th>
        <th>Key age</th>
        <th>Status</th>
        </tr>
        {}
        {}
      </table>
    </p>
    <p>
    Regards,
    <br><?br>
    Jack team
    </p>
  </body>
  </html>""".format(deactivated_key_table, rotate_key_table)

  try:
    #Provide the contents of the email.
    response = ses_client.send_email(
      Destination={
        'ToAddresses': [
          recipient,
        ],
      },
      Message={
        'Body': {
          'Html': {
            'Charset': charset,
            'Data': body_html,
          },
        },
        'Subject': {
          'Charset': charset,
          'Data': subject,
        },
      },
      Source=sender,
    )
  # Display an error if something goes wrong.
  except ClientError as e:
      print(e.response['Error']['Message'])
  else:
      print("Email sent! Message ID: {}, Destination: {}".format(response['MessageId'], recipient))

  output = " Message ID: {}, Destination: {}".format(response['MessageId'], recipient)

  return output
