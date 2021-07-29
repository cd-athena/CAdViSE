### Adaptive Streaming Players Performance Testbed
- Evaluates multi players or ABRs
- Execute experiments on AWS cloud 
- Configurable network attributes are
    - `duration` (seconds)
    - `serverIngress` (kbps)
    - `serverEgress` (kbps)
    - `serverLatency` (ms)
    - `clientIngress` (kbps)
    - `clientEgress` (kbps)
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

#### Acknowledgement

1. Include the link to this repository
2. Cite the following publication:

_Babak Taraghi, Anatoliy Zabrovskiy, Christian Timmerer, and Hermann Hell- wagner. 2020. CAdViSE: Cloud-based Adaptive Video Streaming Evaluation Framework for the Automated Testing of Media Players. In Proceedings of the 11th ACM Multimedia Systems Conference. 349–352. https://doi.org/10.1145/3339825.3393581_
```
@inproceedings{taraghi2020cadvise,
  title={{CAdViSE: Cloud-based Adaptive Video Streaming Evaluation Framework for the Automated Testing of Media Players}},
  author={Taraghi, Babak and Zabrovskiy, Anatoliy and Timmerer, Christian and Hellwagner, Hermann},
  booktitle={Proceedings of the 11th ACM Multimedia Systems Conference},
  pages={349--352},
  year={2020},
  url={https://doi.org/10.1145/3339825.3393581},
  doi={10.1145/3339825.3393581}
}
```