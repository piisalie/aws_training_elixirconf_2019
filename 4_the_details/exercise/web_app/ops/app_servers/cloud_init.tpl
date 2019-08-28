#cloud-config
package_update: true
package_upgrade: true

packages:
  - awscli
  - ruby
  - gdebi-core
  - nginx

ssh_deletekeys: True
ssh_pwauth: False

users:
  - name: app
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      # paul
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMzo8l3K3AHNpp+CxN7+XISGW9wq1ZywviCFLrxaogBAP32Sz6mN6GU+7zpwF8RRxEsyvReqe+CMqG+u2+uksoTbeehKEYVff7V6TxcNoOs8u5fSTwRZdK4+KzGOGZgWzAu2KPtUFBFIvwcxHCKBxdtHCPKJFLiyPUpNQtbt++BOl3LsiwrzK6CfUHMAeSByQWK35Nas2wLP5s+DvZyOemaDfpN+mzXPThhEuQ9kdIikkidjlACOoEWgKBCS69k7MIPpX9RiKHtsEMYLBXLcWu8LfdSRdNe1cxb0o9fJw+yVmUesCwmudxLJAmpmLe8/gzOhJEe6quNPvGNeHXljAP

write_files:
  - path: /usr/bin/find_peers
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      _INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
      _ASG_NAME=$(aws autoscaling describe-auto-scaling-instances --instance-ids="$_INSTANCE_ID" --region=${region} --query "AutoScalingInstances[0].AutoScalingGroupName" --output text)
      aws autoscaling describe-auto-scaling-instances --region ${region} --output text --query "AutoScalingInstances[?AutoScalingGroupName=='$_ASG_NAME'].InstanceId" | xargs -n1 aws ec2 describe-instances --instance-ids $ID --region ${region} --query "Reservations[].Instances[].PrivateIpAddress" --output text

  - path: /etc/profile.d/env_vars.sh
    owner: root:root
    content: |
      export BUILD_BUCKET="${build_bucket}"

  - path: /usr/local/lib/install-codedeploy-agent.sh
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/bash

      function wait_for_dpkg_lock {
        lsof /var/lib/dpkg/lock > /dev/null
        dpkg_is_locked="$?"
        if [ "$dpkg_is_locked" == "0" ]; then
          echo "Waiting for another installation to finish"
          sleep 5
          wait_for_dpkg_lock
        fi
      }

      wait_for_dpkg_lock
      wget https://${bucket_name}.s3.${region}.amazonaws.com/latest/install -O /usr/local/lib/codedeploy-agent-setup
      chmod +x /usr/local/lib/codedeploy-agent-setup
      AWS_REGION=${region} /usr/local/lib/codedeploy-agent-setup auto
      service codedeploy-agent start


  - path: /etc/nginx/sites-enabled/elixir_in_the_jungle
    owner: root:root
    permissions: '0644'
    content: |
      log_format app_log '$proxy_protocol_addr - $remote_user'
                          '[$time_local] "$request" '
                          '$status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent"';

      server {
          listen 80 proxy_protocol default_server;
          server_name _;

          error_log syslog:server=unix:/dev/log;
          access_log syslog:server=unix:/dev/log;

          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

          set_real_ip_from  ${vpc_cidr_block};
          real_ip_header    proxy_protocol;

          location / {
              proxy_http_version  1.1;
              proxy_set_header Host               $host;
              proxy_set_header X-Real-IP          $proxy_protocol_addr;
              proxy_set_header X-Forwarded-For    $proxy_protocol_addr;
              proxy_set_header Upgrade            $http_upgrade;
              proxy_set_header Connection         "upgrade";
              proxy_pass http://localhost:4000;
          }
      }


runcmd:
  - echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts
  - [rm, "/etc/nginx/sites-enabled/default"]
  - [service, nginx, start]
  - /usr/local/lib/install-codedeploy-agent.sh auto
