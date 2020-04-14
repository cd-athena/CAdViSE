### Adaptive Streaming Players Performance Testbed
This is based on https://github.com/ValBr11/docker-evaluation-players
- Works with multi players
- Execute experiments on AWS cloud 
- Configurable network attributes are
    - `availableBandwidth` (kbit)
    - `latency` (ms)
    - `packetLoss` (percentage)
    - `packetDuplicate` (percentage)
    - `packetCorruption` (percentage)
 
#### Requirements
- [docker](https://docs.docker.com/install/)
- [python 2.7](https://www.python.org/downloads/)
- [jq](https://stedolan.github.io/jq)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

#### Guides
- [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [Creating a Key Pair Using Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
- [IAM Roles](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [Security Group Rules](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html)

#### Running on local machine
```
$ sudo ./run.sh --debug --players bitmovin --shaper network.json
```
- Passing `--build` would cause the image to be built on your local machine instead of being fetched from dockerhub.
- `--players` accepts three values `bitmovin`, `shaka` and `dashjs`
- Omitting `--debug` would cause the test to be executed in production mode (no monitoring provided)
- Update network simulator values such as available bandwidth in `network.json`
- Number of experiments can be defined by `--experiments`

#### Running on AWS cloud
```
$ sudo ./run.sh --debug --throttle server --players bitmovin --shaper network.json --awsProfile default --awsKey ppt-key --awsIAMRole SSMEnabled --awsSecurityGroup ppt-security-group
```
Setup AWS CLI on your local machine following the provided guideline, you would need to have the "Access keys" from your
IAM user.
Setup an AWS EC2 key pair and copy the private key in `{PROJECT_ROOT}/aws`.
Define a security group in which ports number `5900` and `22` are allowed to get traffic. 
- Define AWS credentials profile by `--awsProfile`
- You would need to indicate the key pair by `--awsKey` 
- Name your secure(!) security group by `--awsSecurityGroup`
- Pass in an IAM role by `--awsIAMRole`, the role should allow SSM messages, sample:
```
{
    "Effect": "Allow",
    "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
    ],
    "Resource": "*"
}
``` 

#### Monitoring in debug mode

If you are running the test locally, use VNC client to connect to `127.0.0.1:5900` while the test is running.
To monitor multiple players, increase the port number by `1` (eg. `127.0.0.1:5901`) for the next player. 

If you run the tests on AWS cloud each player will have its own public IP address, 
copy the assigned IP address from the terminal, add `:5900` to the end of it
and try to connect with a VNC client.
Note that vnc service will be available only after initialization stage.

Sample: 
```
Connection to 18.185.139.47 port 22 [tcp/ssh] succeeded!
```

```
$ docker build --no-cache --tag babakt/ppt-server:latest .
$ docker push babakt/ppt-server:latest
$ sudo docker exec -it ppt-server speedometer -t eth0 -r eth0
```