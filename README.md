# Elixir In The Jungle Supplemental Files

These files are for educational purposes and take some liberties with
configuration and security for the sake of brevity.

Their purpose is as a learning platform, and not as a solution unto themselves.

* [Navigation](#navigation)
* [General Conventions](#general-conventions)
* [Challenge Solutions](#challenge-solutions)


## Navigation

Each subfolder contains the slides and files specific to that part of the training.

* Part 1: The Physical Machine
* Part 2: The VPC and Bastion, as well as the example Phoenix app configured
for CodeDeploy
* Part 3: The Pipeline, an inital ASG, Launch Configuration, CodeDeploy
  Application etc
* Part 4: An example Phoenix application.  Terraform files can be found in the
  `ops` directory, and important runtime scripts at `scripts`.  The `appspec.yml`
  file contains the CodeDeploy setup.

Notable readme files:
- 2_building_in_the_cloud/exercise/README.md
- 3_a_deployment_pipeline/exercise/README.md
- 4_the_details/exercise/web_app/ops/README.md


## General Conventions

### The `.env` file

`2_building_in_the_cloud/exercise/.env.sample` containes a sample `.env` file
used for setting AWS credentials.

You can use it by copying to a `.env` file `cp .env.sample .env` and updating
it with your own credentials.

You can then source the file `source .env` before running Terraform commands
to add your credentials to the environment.


### Terraform Shared State

** Note **

The Bucket used for terraform state is created and maintained outside of
Terraform.

It will need to have a unique name, and be changed in each `main.tf` file
for your use case.

Some variables in Part 3, are dependent on state/outputs from Part 2.

This is done via the `terraform_remote_state` data block found in the
`3_a_deployment_pipeline/exercise/part_3_the_pipeline/main.tf` file:

```
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "elixir-in-the-jungle-b"
    key = "vpc_state"
    region = "us-east-2"
  }

  workspace = "${terraform.workspace}"
}
```

Variables that are output from the VPC remote state can then be used like:
`data.terraform_remote_state.vpc.outputs.public_subnet_id`

### Terraform workspaces

Terraform has the concept of workspaces, these can be used to separate
stacks like in the case of `staging` environments.

If you wish to spin up multiple environments there are a few things that
need to change.

Most of the changes are in the `variables.tf` files, eg if you're adding an
environment "staging" to the example files.

```
variable "vpc_cidr_blocks" {
  default = {
    example = "10.20.0.0/16"
  }
}
```

should change to something like

```
variable "vpc_cidr_blocks" {
  default = {
    example = "10.20.0.0/16"
    staging = "10.30.0.0/16"
  }
}
```

Additionally a new `.env.example` in the `3_a_deployment_pipeline/exercise/part_3_the_pipeline/`
folder using the convention `.env.YOUR_ENVIRONMENT`

This file is used to provision the environment varibles for the app servers in that
environment.

### How to change regions

There are a few placed the region has to be hard coded.

In each part's `main.tf` file there will be remote state blocks
referencing the remote state bucket and its region.

```
terraform {
  backend "s3" {
    bucket = "elixir-in-the-jungle-b"
    key = "app_servers_state"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "elixir-in-the-jungle-b"
    key = "vpc_state"
    region = "us-east-2"
  }

  workspace = "${terraform.workspace}"
}
```

In addition there is one script (responsible for loading environment
variables from S3) that has the region hard coded:

`2_building_in_the_cloud/exercise/web_app/scripts/getenv` and similarly
`4_the_details/exercise/web_app/scripts/getenv`


## Challenge Solutions

### Part 2 - the build script `exercise/web_app/bin/build`

```
ssh -T $1 <<-SSHCMDS
    mkdir -p builds &&
    tar -C builds -xf $_archive &&
    cd builds &&
    mix local.rebar --force &&
    mix local.hex --force &&
    mix deps.get --only prod &&
    cd assets &&
    npm install &&
    npm run deploy &&
    cd .. &&
    export MIX_ENV=prod &&
    mix phx.digest &&
    mix release --overwrite --path ./release &&
    cp -r ./scripts ./release/ &&
    cp ./appspec.yml ./release &&
    tar -C release . -zcf latest.tar.gz &&
    publish_release ./latest.tar.gz latest.tar.gz &&
    cd .. &&
    rm $_archive &&
    rm -rf builds
SSHCMDS
```


### Part 3 - CodePipeline `exercise/part_3_the_pipeline/codepipeline.tf`


```
resource "aws_codepipeline" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "App-Change"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      output_artifacts = ["release"]

      configuration = {
        S3Bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
        S3ObjectKey = "latest.tar.gz"
        PollForSourceChanges = "true"
      }
    }

    action {
      name = "Config-Change"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      output_artifacts = ["env"]

      configuration = {
        S3Bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
        S3ObjectKey = "env"
        PollForSourceChanges = "true"
      }
    }

  }

  stage {
    name = "Deploy"

    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      input_artifacts = ["release"]
      version = "1"

      configuration = {
        ApplicationName = "${aws_codedeploy_app.app_servers.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.app_servers.deployment_group_name}"
      }
    }
  }
}
```
