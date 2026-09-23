# AWS resources

Everything lives in one region. Do these in order; later steps reference earlier ones. `scripts/aws-bootstrap.sh` does 1 to 4 and the GitHub values; the instance (5) is created by hand because it has too many user choices.

## 1. ECR repository

Private, scan on push, lifecycle rule keeping the last 20 images. The name (for example `<app>-backend`) is the `ECR_REPOSITORY` GitHub variable; the workflow builds the full URI from the login step's registry output.

## 2. S3 backup bucket

Bucket names are global, so `<app>-backups` may be taken; fall back to `<app>-backups-<account-id>`. Block all public access. Lifecycle rule expiring objects after 30 days. The instance role gets `s3:PutObject` only, so a compromised box cannot read or delete history.

## 3. Instance role and profile

Trusted entity EC2. Attach `AmazonSSMManagedInstanceCore` (deploys over SSM), `AmazonEC2ContainerRegistryReadOnly` (pull images, includes `GetAuthorizationToken`), and an inline policy with `s3:PutObject` on `arn:aws:s3:::<bucket>/*`. Create the instance profile with the same name and associate it with the instance. Associating immediately after creation can fail with an invalid profile error while IAM propagates; retry for a minute.

## 4. GitHub OIDC role

If the account has no identity provider for `https://token.actions.githubusercontent.com` with audience `sts.amazonaws.com`, create it first.

Trust policy condition, with both subject forms because repos may have the immutable subject claim enabled (`gh api repos/<org>/<repo>/actions/oidc/customization/sub` shows `sub_claim_prefix` when it is):

```json
"StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
"StringLike":   { "token.actions.githubusercontent.com:sub": [
  "repo:<org>/<repo>:environment:production",
  "repo:<org>@<org-id>/<repo>@<repo-id>:environment:production" ] }
```

Permissions, least privilege:

- `ecr:GetAuthorizationToken` on `*`
- `ecr:BatchCheckLayerAvailability`, `CompleteLayerUpload`, `InitiateLayerUpload`, `PutImage`, `UploadLayerPart`, `BatchGetImage`, `GetDownloadUrlForLayer`, `DescribeImages`, `DescribeRepositories` on the repository ARN
- `ssm:SendCommand` on the instance ARN and on `arn:aws:ssm:<region>::document/AWS-RunShellScript`
- `ssm:GetCommandInvocation`, `ssm:ListCommandInvocations` on `*`

The role ARN is the `AWS_DEPLOY_ROLE_ARN` GitHub secret.

## 5. EC2 instance

| Setting | Value |
|---|---|
| AMI | Ubuntu Server LTS, 64-bit x86 (runners build amd64) |
| Type | t3.small for a small API |
| Storage | 30 GB gp3, delete on termination off |
| Security group | 80 and 443 from anywhere; 22 only if needed, SSM replaces it |
| Instance profile | the role from step 3 |

After launch: termination protection on, Elastic IP allocated and associated (do this before DNS, association replaces the public IP), DNS `A` record for the API hostname pointing at it, TTL 300.

## 6. GitHub environment

Environment named `production` (must match the trust policy and the workflow). Variables `AWS_REGION`, `ECR_REPOSITORY`, `EC2_INSTANCE_ID`; secret `AWS_DEPLOY_ROLE_ARN`. Environment secrets show on the environment's page, not under the repository's "Secrets and variables" page; users regularly look in the wrong place.

Set them with the CLI:

```sh
gh variable set AWS_REGION --env production --body <region> -R <org>/<repo>
gh secret set AWS_DEPLOY_ROLE_ARN --env production --body <arn> -R <org>/<repo>
```

## Verifying

- `aws ssm describe-instance-information` lists the instance with `PingStatus: Online` once the agent has registered. Restart the agent on the box if it does not appear within a few minutes of attaching the profile.
- Rerun the failed deploy job. A green `configure-aws-credentials` step proves OIDC, a green build step proves ECR push, a green SSM step proves the whole path.
