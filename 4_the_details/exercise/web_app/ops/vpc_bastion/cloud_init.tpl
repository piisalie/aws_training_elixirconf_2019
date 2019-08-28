#cloud-config

ssh_deletekeys: True
ssh_pwauth: False

users:
  - name: paul
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMzo8l3K3AHNpp+CxN7+XISGW9wq1ZywviCFLrxaogBAP32Sz6mN6GU+7zpwF8RRxEsyvReqe+CMqG+u2+uksoTbeehKEYVff7V6TxcNoOs8u5fSTwRZdK4+KzGOGZgWzAu2KPtUFBFIvwcxHCKBxdtHCPKJFLiyPUpNQtbt++BOl3LsiwrzK6CfUHMAeSByQWK35Nas2wLP5s+DvZyOemaDfpN+mzXPThhEuQ9kdIikkidjlACOoEWgKBCS69k7MIPpX9RiKHtsEMYLBXLcWu8LfdSRdNe1cxb0o9fJw+yVmUesCwmudxLJAmpmLe8/gzOhJEe6quNPvGNeHXljAP

  - name: james
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDE/EQWIzJwzYJ5HPGiF5dci5HUfHJZpMSl6smaQZrQzM9cFqoRcIks6xlFJqgs41xugipf6AqJoqMLVbTmTaW/bhZdxrcuZ5CSdtmMtHjITtpH5PUZnP9SdBVYzFvWBzEp1IjXMXU88QZvW12sW6eT1PQsCoGgfpVarN7INgFS6J9nw5K1HNBOzKLDMhOEEoiIpx+vlXfxiWDTbXBkueleG1QIr+BJQ1da2yrkdvnP7MFNU4YRlFjyX2fzBJRFNE2R+wj8+E7nQdkAuZCBkEbV53jf7JEwYRkPH+KdHgexvdNYAAw/hD6/0uY+JYZsWXxR1jO6e8EzwmlK830yZ+C1

apt:
  sources:
    yarn:
      source: deb https://dl.yarnpkg.com/debian/ stable main
      keyid: 1646B01B86E50310

    nodesource:
      source: deb https://deb.nodesource.com/node_10.x $RELEASE main
      # from: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
      keyid: 9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280

    erlang_solutions:
      source: deb http://binaries.erlang-solutions.com/debian $RELEASE contrib
      # from https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc
      keyid: 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA

packages:
  - awscli
  - build-essential
  - ["esl-erlang", "1:22.0.7-1"]
  - ["elixir", "1.9.1-1"]
  - nodejs
  - yarn

package_upgrade: true

write_files:
  - path: /usr/bin/known_hosts
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      _LATEST_DEPLOYMENT=$(aws deploy list-deployments --application ${codedeploy_app_name} --deployment-group ${codedeploy_app_name}-app-servers --region ${region} --output text --query "deployments[0]")
      _ASG_NAME=CodeDeploy_${codedeploy_app_name}-app-servers_$_LATEST_DEPLOYMENT
      aws autoscaling describe-auto-scaling-instances --region ${region} --output text --query "AutoScalingInstances[?AutoScalingGroupName=='$_ASG_NAME'].InstanceId" | xargs -n1 aws ec2 describe-instances --instance-ids $ID --region ${region} --query "Reservations[].Instances[].PrivateIpAddress" --output text


  - path: /etc/profile.d/env_vars.sh
    owner: root:root
    content: |
      export BUILD_BUCKET="${bucket_name}"
      export SLACK_WEBHOOK="${slack_webhook}"

  - path: /usr/bin/notify_slack
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/bash
      curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$1\"}" $SLACK_WEBHOOK
  - path: /usr/bin/publish_release
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/bash
      aws s3 cp $1 s3://$BUILD_BUCKET/$2 --region ${region}
runcmd:
  - [curl, -X, POST, -H, 'Content-type: application/json', --data, '{"text":"Build server setup complete!"}', "${slack_webhook}" ]
