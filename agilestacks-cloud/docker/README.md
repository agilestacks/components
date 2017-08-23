# AgileStacks Cloud

A component that to bootstrap AgileStacks resources in cloud account of the client and optionally bootstrap cross-account-role. This script will create a s3 bucket and a hosted zone in client's cloud and propagate it in Base account (Agile Stacks).

# Run stack

- `make deploy KIND=creds`  to run stack with static AWS credentials. It will also create a cross account IAM role
- `make deploy KIND=role` uses cross account role to access

# Environment variables variables
 
Terraform 0.9+ should be installed. 
- `AWS_DEFAULT_PROFILE` - base cloud account credentials are taken from profile or EC2 instance profile
- `AWS_DEFAULT_REGION` - region of base cloud account
- `KIND` - `creds`, `role` or `creds-with-iam`
- `TF_VAR_name` - name of the cloud account (in terms of Control Plane)
- `TF_VAR_base_domain` - base domain (a hosted zone name in out account)
- `TF_VAR_client_aws_region` - AWS region in cloud account

### If TYPE=creds
- `TF_VAR_client_aws_access_key` - access key for client cloud account
- `TF_VAR_client_aws_secret_key` - secret key for client cloud account

### If TYPE=role
- `TF_VAR_assume_role_arn` - ARN of the role (from client cloud account) cross account role
- `TF_VAR_external_id` - (OPTIONAL) if not set, will be derived from role arn


# Getting output

`make output` will print output in JSON format


