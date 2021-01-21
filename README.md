### Adaptive Streaming Players Performance Testbed
- Evaluates multi players or ABRs
- Execute experiments on AWS cloud 
- Configurable network attributes are
    - `duration` (seconds)
    - `serverIngress` (kbit)
    - `serverEgress` (kbit)
    - `serverLatency` (ms)
    - `clientIngress` (kbit)
    - `clientEgress` (kbit)
    - `clientLatency` (ms)
 
**Note** The combination of `bandwidth` and `latency` in one node is not allowed.


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

#### Running on AWS cloud
```
./run.sh --players bitmovin --title bbb1 --shaper network/network0.json --awsKey ppt-key
```

#### Monitoring in debug mode

Copy the assigned IP address from the terminal, add `:5900` to the end of it
and try to connect with a VNC client.
Note that vnc service will be available only after initialization stage.
