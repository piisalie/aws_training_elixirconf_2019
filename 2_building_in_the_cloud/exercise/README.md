# Elixir in The Jungle

protips:
- .env file for credentials
- tags
- terraform workspaces

## Part 2 - The VPC, and the Bastion

To use these files, you must:
1. Have Terraform 0.12.6
1. Generate privileged AWS credentials. (define required cred, ec2, s3, iam)
1. Add generated access key, and access key id to the `./.env` file.
1. Add your user and public key to the `users` section of `cloud_init.tpl`
1. Create a private S3 bucket, with versioning enabled, to use for Terraform Remote State etc (and add the name of the bucket to the `main.tf` files in each directory)

- `terraform init` will initialize the backend etc
- `terraform workspace new example` create a new workspace, the expected
   workspace name for the files in this config is `example`
- `terraform plan` will describe what changes are needed
- `terraform apply` will apply the changes

Resources:
- AWS access keys https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html
- Install Terraform https://www.terraform.io/downloads.html
- Terraform Remote State S3 Backend https://www.terraform.io/docs/backends/types/s3.html

