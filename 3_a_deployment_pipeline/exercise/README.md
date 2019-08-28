# Elixir in The Jungle

## Part 3 - The Pipeline

** You must run Part 2 prior to running the files here **

Terraform Commands:
- `terraform init` will initialize the backend etc
- `terraform workspace new example` create a new workspace, the expected
   workspace name for the files in this config is `example`
- `terraform plan` will describe what changes are needed
- `terraform apply` will apply the changes

### The Initial AutoScaing Group

CodeDeploy Blue/Green Deployments require an Auto Scaling Group to copy
configuration from.  Once copied it will destroy the old auto scaling
group.  For this reason, we really only need to create an ASG via Terraform
during initial provisioning.  This is done via an `initial_asg` option.

`terraform apply -var "inital_asg=true"`


### The Launch Config Oddity

An auto scaling group provisions servers based on the launch configuration.

When an auto scaling group is copied (when Code Deploy deploys code) the
new auto scaling group will reference the original launch configuration.

Currently it is not possible to edit a launch config in place, nor is it
possible to use the "create before destroy" option of terraform without
breaking the launch template's relationship with the existing auto scaling
group.

This makes editing your launch configuration a little odd.  The best way
I've found is to:

1. use the AWS web UI to copy the launch config
2. reassign the existing autoscaling group to the copy of the launch config
3. run `terraform apply` to enact the changes in the launch config
4. reassign the existing autoscaling  group back to the old (newly edited)
   launch config
5. delete the copy


### Server Health Checks

The application from part 2 supports a `/ping` route

In the `load_balancer.tf` file there is some commented code to support a
more robust health check using this route.

In a real world project, you probably want to update the plug's function that
handles the `/ping` route to ensure that your app can talk to other external
services it may be dependent on.


### SSL

In an actual application, you'll want to redirect all traffic to use HTTPS.

To setup SSL you'll need to:
1. have a validated certificate in AWS that you can find and reference
   in the load balancer listener. (see commented code in `load_balancer.tf`)
2. setup the ssl listener on the load balancer
3. uncomment the port 443 communication blocks in the `security_groups.tf`
   file for both the app servers and load balancer
4. update nginx to support 443 traffic (See below)

An example nginx config to redirect traffic to an apex domain can be found below,
note the `nginx_catch_all`, and `nginx_apex` varibles that need to be populated.

eg:
```
nginx_catch_all = *.your.domain.com
nginx_apex = your.domain.com
```


```
      log_format app_log '$proxy_protocol_addr - $remote_user'
                          '[$time_local] "$request" '
                          '$status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent"';

      server {
          listen 80 proxy_protocol;
          server_name ${nginx_catch_all} ${nginx_apex};

          error_log syslog:server=unix:/dev/log;
          access_log syslog:server=unix:/dev/log;

          return 301 https://${nginx_apex}$request_uri;
      }

      server {
          listen 443 proxy_protocol;
          server_name ${nginx_catch_all};

          error_log syslog:server=unix:/dev/log;
          access_log syslog:server=unix:/dev/log;

          return 301 https://${nginx_apex}$request_uri;
      }

      server {
         listen 443 proxy_protocol;
         server_name ${nginx_apex};

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
```

