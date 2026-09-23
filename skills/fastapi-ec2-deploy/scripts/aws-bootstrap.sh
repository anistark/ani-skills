#!/usr/bin/env bash
# Creates the AWS side for the deploy pipeline and sets the GitHub environment values.
# Idempotent: safe to rerun. Needs the AWS CLI logged in as an administrator and gh
# logged in with access to the repo. Ask the user before running: it creates IAM roles.
#
#   aws-bootstrap.sh <app> <region> <instance-id> <github-org/repo> [environment]
set -euo pipefail
APP="${1:?app name}"; REGION="${2:?region}"; INSTANCE="${3:?instance id}"; GH_REPO="${4:?org/repo}"
ENVIRONMENT="${5:-production}"
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REPO="$APP-backend"; BUCKET="$APP-backups"; IROLE="$APP-instance"; DROLE="github-$APP-deploy"
step() { echo; echo "### $*"; }

step "ECR repository $REPO"
aws ecr describe-repositories --repository-names "$REPO" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --image-scanning-configuration scanOnPush=true --query repository.repositoryUri --output text
aws ecr put-lifecycle-policy --repository-name "$REPO" --lifecycle-policy-text \
  '{"rules":[{"rulePriority":1,"description":"keep last 20 images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":20},"action":{"type":"expire"}}]}' >/dev/null

step "S3 bucket"
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  if ! aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" $( [ "$REGION" != us-east-1 ] && echo --create-bucket-configuration LocationConstraint="$REGION" ) >/dev/null 2>&1; then
    BUCKET="$APP-backups-$ACCOUNT"
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" $( [ "$REGION" != us-east-1 ] && echo --create-bucket-configuration LocationConstraint="$REGION" ) >/dev/null
  fi
fi
echo "bucket: $BUCKET (put this in the server env file as BACKUP_BUCKET)"
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" --lifecycle-configuration \
  '{"Rules":[{"ID":"expire-30d","Status":"Enabled","Filter":{"Prefix":""},"Expiration":{"Days":30}}]}' >/dev/null

step "Instance role $IROLE"
aws iam get-role --role-name "$IROLE" >/dev/null 2>&1 || aws iam create-role --role-name "$IROLE" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws iam attach-role-policy --role-name "$IROLE" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name "$IROLE" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam put-role-policy --role-name "$IROLE" --policy-name backups-write \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::$BUCKET/*\"}]}"
aws iam get-instance-profile --instance-profile-name "$IROLE" >/dev/null 2>&1 || {
  aws iam create-instance-profile --instance-profile-name "$IROLE" >/dev/null
  aws iam add-role-to-instance-profile --instance-profile-name "$IROLE" --role-name "$IROLE"; }
if ! aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values="$INSTANCE" Name=state,Values=associated \
     --query 'IamInstanceProfileAssociations[0].IamInstanceProfile.Arn' --output text | grep -q "$IROLE"; then
  for i in 1 2 3 4 5 6; do
    aws ec2 associate-iam-instance-profile --instance-id "$INSTANCE" --iam-instance-profile Name="$IROLE" >/dev/null 2>&1 && { echo "profile associated"; break; }
    echo "waiting for IAM propagation ($i)"; sleep 10
  done
fi

step "GitHub OIDC role $DROLE"
PROVIDER="arn:aws:iam::$ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER" >/dev/null 2>&1 \
  || aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com >/dev/null
# Repos with the immutable subject claim present a different subject; allow both forms.
PREFIX="$(gh api "repos/$GH_REPO/actions/oidc/customization/sub" --jq '.sub_claim_prefix // empty' 2>/dev/null || true)"
SUBS="\"repo:$GH_REPO:environment:$ENVIRONMENT\""
[ -n "$PREFIX" ] && SUBS="$SUBS,\"$PREFIX:environment:$ENVIRONMENT\""
TRUST="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"$PROVIDER\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\",\"Condition\":{\"StringEquals\":{\"token.actions.githubusercontent.com:aud\":\"sts.amazonaws.com\"},\"StringLike\":{\"token.actions.githubusercontent.com:sub\":[$SUBS]}}}]}"
if aws iam get-role --role-name "$DROLE" >/dev/null 2>&1; then
  aws iam update-assume-role-policy --role-name "$DROLE" --policy-document "$TRUST"
else
  aws iam create-role --role-name "$DROLE" --assume-role-policy-document "$TRUST" \
    --description "GitHub Actions: push $APP image to ECR and deploy over SSM" >/dev/null
fi
aws iam put-role-policy --role-name "$DROLE" --policy-name deploy --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[
 {\"Effect\":\"Allow\",\"Action\":\"ecr:GetAuthorizationToken\",\"Resource\":\"*\"},
 {\"Effect\":\"Allow\",\"Action\":[\"ecr:BatchCheckLayerAvailability\",\"ecr:CompleteLayerUpload\",\"ecr:InitiateLayerUpload\",\"ecr:PutImage\",\"ecr:UploadLayerPart\",\"ecr:BatchGetImage\",\"ecr:GetDownloadUrlForLayer\",\"ecr:DescribeImages\",\"ecr:DescribeRepositories\"],\"Resource\":\"arn:aws:ecr:$REGION:$ACCOUNT:repository/$REPO\"},
 {\"Effect\":\"Allow\",\"Action\":\"ssm:SendCommand\",\"Resource\":[\"arn:aws:ec2:$REGION:$ACCOUNT:instance/$INSTANCE\",\"arn:aws:ssm:$REGION::document/AWS-RunShellScript\"]},
 {\"Effect\":\"Allow\",\"Action\":[\"ssm:GetCommandInvocation\",\"ssm:ListCommandInvocations\"],\"Resource\":\"*\"}]}"

step "GitHub environment $ENVIRONMENT"
gh api -X PUT "repos/$GH_REPO/environments/$ENVIRONMENT" >/dev/null
gh variable set AWS_REGION --env "$ENVIRONMENT" --body "$REGION" -R "$GH_REPO"
gh variable set ECR_REPOSITORY --env "$ENVIRONMENT" --body "$REPO" -R "$GH_REPO"
gh variable set EC2_INSTANCE_ID --env "$ENVIRONMENT" --body "$INSTANCE" -R "$GH_REPO"
gh secret set AWS_DEPLOY_ROLE_ARN --env "$ENVIRONMENT" --body "arn:aws:iam::$ACCOUNT:role/$DROLE" -R "$GH_REPO"

step "Protect the instance"
aws ec2 modify-instance-attribute --instance-id "$INSTANCE" --disable-api-termination
DEV="$(aws ec2 describe-instances --instance-ids "$INSTANCE" --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].DeviceName' --output text)"
aws ec2 modify-instance-attribute --instance-id "$INSTANCE" --block-device-mappings "[{\"DeviceName\":\"$DEV\",\"Ebs\":{\"DeleteOnTermination\":false}}]"

echo; echo "Done. Next: restart the SSM agent on the box, then check:"
echo "  aws ssm describe-instance-information --filters Key=InstanceIds,Values=$INSTANCE"
