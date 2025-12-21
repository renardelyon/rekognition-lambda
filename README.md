# Rekognition Lambda Monitor

![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-FF9900?style=flat-square&logo=amazon-aws)

AWS Lambda function written in Go that monitors Rekognition custom label models and automatically stops the model when it is turned on.

## Features

- **Model Status Check**: Queries AWS Rekognition to check if a custom label model is running (HOSTED status)
- **Docker Support**: Run locally in Docker container before deploying to AWS Lambda
- **EventBridge Integration**: Seamless integration with AWS EventBridge for scheduled invocation

## Prerequisites

- Go 1.21 or later
- AWS CLI configured with credentials
- AWS Lambda execution role with permissions for:
  - `rekognition:DescribeProjectVersions`
  - `rekognition:StopProjectVersion`
- AWS Rekognition custom label model deployed

## Deployment Options

### Using Docker (Local Testing - Recommended)

```bash
chmod +x docker-build.sh docker-test.sh
./docker-build-local.sh
```

See [DOCKER.md](DOCKER.md) for detailed Docker instructions.


### Event Input Structure

The Lambda function is triggered by EventBridge and expects the following event structure:

```json
{
 "modelArn": "arn:aws:rekognition:us-east-1:123456789:project/my-project/version/my-project.2025-12-08T08.23.04/123456789",
  "projectArn": "arn:aws:rekognition:us-east-1:123456789:project/my-project/123456789"
}
```

Update `event.json` with your actual values:

```json
{
  "modelArn": "arn:aws:rekognition:us-east-1:123456789:project/my-project/version/my-project.2025-12-08T08.23.04/123456789",
  "projectArn": "arn:aws:rekognition:us-east-1:123456789:project/my-project/123456789"
}
```

## Usage with EventBridge

### Create EventBridge Rule

Create a scheduled rule to invoke the Lambda function at regular intervals:

```bash
# Create the rule (every 5 minutes)
aws events put-rule \
  --name rekognition-monitor-schedule \
  --schedule-expression "rate(5 minutes)"

# Add the Lambda function as a target
aws events put-targets \
  --rule rekognition-monitor-schedule \
  --targets "Id"="1","Arn"="arn:aws:lambda:region:account:function:RekognitionModelMonitor"

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name RekognitionModelMonitor \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:region:account:rule/rekognition-monitor-schedule
```

### EventBridge Rule with Custom Input

To pass specific parameters, create a rule with input transformation:

```bash
aws events put-targets \
  --rule rekognition-monitor-schedule \
  --targets Id=1,\
Arn=arn:aws:lambda:region:account:function:RekognitionModelMonitor,\
RoleArn=arn:aws:iam::account:role/EventBridgeRole,\
Input='{"projectArn":"arn:aws:rekognition:us-east-1:123456789012:project/MyProject","instanceId":"i-0123456789abcdef0"}'
```

### Schedule Examples

```bash
# Every 5 minutes
rate(5 minutes)

# Every hour
rate(1 hour)

# Every 30 minutes during business hours (9 AM - 5 PM weekdays)
cron(*/30 9-17 ? * MON-FRI *)

# Every morning at 8 AM UTC
cron(0 8 * * ? *)
```
## Support

For issues or questions, review:
- AWS Rekognition documentation: https://docs.aws.amazon.com/rekognition/
- AWS Lambda documentation: https://docs.aws.amazon.com/lambda/
- AWS EC2 documentation: https://docs.aws.amazon.com/ec2/
- AWS SDK for Go documentation: https://aws.github.io/aws-sdk-go-v2/
