hanat - A bash script for high-availability NAT for EC2 instances
=================================================================

Overview
--------

- When this script is starting-up
  - Setting sysctl variables to forwarding packet
  - Adding IP masquerade rule
  - Disabling the Source/Dest Check of my own instance
  - Configuring route of subnets which have responsibility

- Ordinary

  ![](https://github.com/kteru/hanat/wiki/images/01.png)

- When "i-AAAAAAAA" is failure
  - Replacing route table

  ![](https://github.com/kteru/hanat/wiki/images/02.png)

Requirements
------------

- 2 EC2 instances which have EIP or Public IP
  - No need to select "NAT instance"

- IAM Policies
  - ec2:ModifyInstanceAttribute
  - ec2:DescribeRouteTables
  - ec2:ReplaceRouteTableAssociation

- Commands
  - aws (aws-cli)
  - awk (gawk or mawk)
  - curl
  - sysctl
  - iptables
  - sleep

Installation
------------

```
# git clone https://github.com/kteru/hanat.git /opt/hanat
# cp -a /opt/hanat/docs/init_hanat.sh /etc/init.d/hanat
# chkconfig --add hanat
# chkconfig hanat on
```

Configuration
-------------

```
# cd /opt/hanat/conf
# cp -a hanat.conf.sample hanat.conf
# vi hanat.conf
```

### Example configuration (suitable for Overview of the above)

#### i-AAAAAAAA

`hanat.conf`

```
# export AWS_ACCESS_KEY_ID=<IAM_Roles_is_recommended>
# export AWS_SECRET_ACCESS_KEY=<IAM_Roles_is_recommended>
export AWS_DEFAULT_REGION=ap-northeast-1

CHECK_PARTNER_CMD='ping -nq -W 1 -c 3 -i 0.3 172.31.252.254'
CHECK_PARTNER_INTVL=5

RTB_VIA_OWN=rtb-AAAAAAAA
SUBNETS_ACT="subnet-AAAA0001 subnet-AAAA0002"
SUBNETS_STB="subnet-BBBB0001 subnet-BBBB0002"
```

#### i-BBBBBBBB

`hanat.conf`

```
# export AWS_ACCESS_KEY_ID=<IAM_Roles_is_recommended>
# export AWS_SECRET_ACCESS_KEY=<IAM_Roles_is_recommended>
export AWS_DEFAULT_REGION=ap-northeast-1

CHECK_PARTNER_CMD='ping -nq -W 1 -c 3 -i 0.3 172.31.251.254'
CHECK_PARTNER_INTVL=5

RTB_VIA_OWN=rtb-BBBBBBBB
SUBNETS_ACT="subnet-BBBB0001 subnet-BBBB0002"
SUBNETS_STB="subnet-AAAA0001 subnet-AAAA0002"
```

Starting-up
-----------

```
# service hanat start
```

