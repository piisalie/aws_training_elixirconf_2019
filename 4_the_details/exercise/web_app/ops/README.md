# Example Phoenix Ops Config

## Requirements:

1. Have Terraform 0.12.6
1. Generate privileged AWS credentials. (define required cred, ec2, s3, iam)
1. Add generated access key, and access key id to the `./.env` file. (see .env.sample)
1. Add a secure DB password and user to the ./.env file. (see .env.sample)
1. Add your user and public key to the `users` section of `cloud_init.tpl`
1. Create a private S3 bucket, with versioning enabled, to use for Terraform Remote State etc (and add the name of the bucket to the `main.tf` files in each directory)

- `terraform init` will initialize the backend etc
- `terraform workspace new example` create a new workspace, the expected
   workspace name for the files in this config is `example`
- `terraform plan` will describe what changes are needed
- `terraform apply` will apply the changes

## Setup:

1. source your `./.env` file
1. Run `terraform apply` in `./vpc_bastion`
1. Run `terraform apply -var "initial_asg=true"` in `./app_servers`
1. Run `terraform apply` in `./database`


