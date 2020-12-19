# Request Broker

## Goal

The goal of Request Broker service is to be an intermediary between Requesters and Providers within the OCF Collab network serving couple of purposes:

* Authenticate requests and make sure they come from authorized Requesters
* Allow Requesters to search for competency frameowks across the whole network
* Allow Requester Node Agents to fetch competency frameworks from multiple providers using single, common API
* Enable Requesters to receive competency frameworks in desired metamodel via Metamodel Interchange
* Collect Transaction Log allowing insight into nodes usage pattern


## Node Directories

Node Directory, represented by `NodeDirectory` database model, is a collection of competency frameworks exposed to the network by specific provider. Competency frameworks are represented by Node Directory Entry files in a specified S3 bucket within configured AWS account.

Current list of node directoties is maintained within `config/registry_directory.json` file present in this repository.

In order to ensure proper configuration in the database run `registry_directory:sync_from_file` Rake task.

### AWS configuration

Use `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_REGION` environment variables to specify access credentials for S3 buckets assigned to Node Directories.


## Request Node Agents

All requests come from Request Node Agents which are the end user access points for searching and retrieving competency frameworks.

Specific Request Node Agents are authenticated using [OAuth 2.0 protocol](https://oauth.net/2/) with [JWT](https://jwt.io/introduction/) tokens and Request Broker serves as an identity provider.

Request Broker doesn't authenticate specific end users and instead uses [Client Credential flow](https://oauth.net/2/grant-types/client-credentials/) for application based authentication.

### Adding Request Node Agents

In order to enable Request Node Agent access to the network `OauthApplication` record has to be created.

THe only required attribute is `name`. `uid` and `secret`, which serve as OAuth 2.0 client credentials are generated automatically.

Specify `node_directory` association if the Request Node Agent belongs to a node member that also exposes its own directory to the network. The association is used only for insight within Transaction Log.

### JWT tokens


## Transaction Logs

Request Broker generates a log containing detailed information about specific steps within all brokered transactions.

The log file location is `log/transactions.log`.

In order to allow easy access to the log it's fed into AWS CloudWatch and then ElasticSearch index with Kibana front-end.

### Setup

#### AWS IAM role

In order to allow EC2 instance to push logs to CloudWatch the instance needs an [IAM Role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html) configured as in [Create IAM Roles and Users for Use with the CloudWatch Agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-iam-roles-for-cloudwatch-agent.html) instructions.

After creating the role with appropiate permissions policy attach it to the EC2 instance(s) running Request Broker as in [Attaching an IAM role to an instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#attach-iam-role) instructions.

#### CloudWatch agent on EC2 instance(s)

After creating IAM role install and configure CloudWatch agent as in [Install and Configure the CloudWatch Logs Agent on a Running EC2 Linux Instance](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html).

Skip "Step 1: Configure Your IAM Role or User for CloudWatch Logs" and use the role created in previous step.

Use following timestamp format when configuring the agent: `%Y-%m-%dT%H:%M:%S.%fZ`.

##### Sample `/var/awslogs/etc/awslogs.conf` configuration

```
[/var/deploy/t3_ocf_collab__rb/web_head/shared/log/transactions.log]
datetime_format = %Y-%m-%dT%H:%M:%S.%fZ
file = /var/deploy/t3_ocf_collab__rb/web_head/shared/log/transactions.log
buffer_duration = 5000
log_stream_name = request-broker-transaction-log-production
initial_position = start_of_file
log_group_name = request-broker-production
```

#### Streaming CloudWatch logs to ElasticSearch

Follow [Streaming CloudWatch Logs Data to Amazon Elasticsearch Service](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_ES_Stream.html) instructions.
