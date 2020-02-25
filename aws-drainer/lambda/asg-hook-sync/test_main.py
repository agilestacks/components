import unittest

import os, sys
import boto3

script_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, script_dir + os.sep + "lib")

from moto import mock_autoscaling, mock_elbv2, mock_ec2
from main import find_asg_by_tag


@mock_ec2
def setup_networking():
    ec2 = boto3.resource("ec2", region_name="us-east-1")
    vpc = ec2.create_vpc(CidrBlock="10.11.0.0/16")
    subnet1 = ec2.create_subnet(
        VpcId=vpc.id, CidrBlock="10.11.1.0/24", AvailabilityZone="us-east-1a"
    )
    subnet2 = ec2.create_subnet(
        VpcId=vpc.id, CidrBlock="10.11.2.0/24", AvailabilityZone="us-east-1b"
    )
    return {"vpc": vpc.id, "subnet1": subnet1.id, "subnet2": subnet2.id}


@mock_ec2
def setup_instance_with_networking(image_id, instance_type):
    mock_data = setup_networking()
    ec2 = boto3.resource("ec2", region_name="us-east-1")
    instances = ec2.create_instances(
        ImageId=image_id,
        InstanceType=instance_type,
        MaxCount=1,
        MinCount=1,
        SubnetId=mock_data["subnet1"],
    )
    mock_data["instance"] = instances[0].id
    return mock_data


@mock_autoscaling
@mock_elbv2
def init():
    INSTANCE_COUNT = 2
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    asg_client = boto3.client("autoscaling", region_name="us-east-1")
    elbv2_client = boto3.client("elbv2", region_name="us-east-1")

    response = elbv2_client.create_target_group(
        Name="a-target",
        Protocol="HTTP",
        Port=8080,
        VpcId=setup_networking()["vpc"],
        HealthCheckProtocol="HTTP",
        HealthCheckPort="8080",
        HealthCheckPath="/",
        HealthCheckIntervalSeconds=5,
        HealthCheckTimeoutSeconds=5,
        HealthyThresholdCount=5,
        UnhealthyThresholdCount=2,
        Matcher={"HttpCode": "200"},
    )
    target_group_arn = response["TargetGroups"][0]["TargetGroupArn"]

    asg_client.create_launch_configuration(
        LaunchConfigurationName="test_launch_configuration"
    )

    # create asg, attach to target group on create
    asg_client.create_auto_scaling_group(
        AutoScalingGroupName="test_asg",
        LaunchConfigurationName="test_launch_configuration",
        MinSize=0,
        MaxSize=INSTANCE_COUNT,
        DesiredCapacity=INSTANCE_COUNT,
        TargetGroupARNs=[target_group_arn],
        VPCZoneIdentifier=setup_networking()["subnet1"],
        Tags=[
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'k8s.io/node-pool/k8s-test',
                'Value': 'owned',
                'PropagateAtLaunch': True
            },
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'k8s.io/node-pool/kind',
                'Value': 'worker',
                'PropagateAtLaunch': True
            },
        ],
    )
    asg_client.create_auto_scaling_group(
        AutoScalingGroupName="test_asg5",
        LaunchConfigurationName="test_launch_configuration",
        MinSize=0,
        MaxSize=INSTANCE_COUNT,
        DesiredCapacity=INSTANCE_COUNT,
        TargetGroupARNs=[target_group_arn],
        VPCZoneIdentifier=setup_networking()["subnet1"],
        Tags=[
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'k8s.io/node-pool/k8s-test',
                'Value': 'owned',
                'PropagateAtLaunch': True
            },
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'k8s.io/node-pool/kind',
                'Value': 'worker',
                'PropagateAtLaunch': True
            },
        ],
    )
    asg_client.create_auto_scaling_group(
        AutoScalingGroupName="test_asg3",
        LaunchConfigurationName="test_launch_configuration",
        MinSize=0,
        MaxSize=INSTANCE_COUNT,
        DesiredCapacity=INSTANCE_COUNT,
        TargetGroupARNs=[target_group_arn],
        VPCZoneIdentifier=setup_networking()["subnet1"],
        Tags=[
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'k8s.io/node-pool/kind',
                'Value': 'master',
                'PropagateAtLaunch': True
            },
            {
                'ResourceId': 'string',
                'ResourceType': 'string',
                'Key': 'kubernetes.io/cluster/name',
                'Value': 'master-k8s-reinis4aws-dev-superhub-io',
                'PropagateAtLaunch': True
            }
        ],
    )
    # create asg without attaching to target group
    asg_client.create_auto_scaling_group(
        AutoScalingGroupName="test_asg2",
        LaunchConfigurationName="test_launch_configuration",
        MinSize=0,
        MaxSize=INSTANCE_COUNT,
        DesiredCapacity=INSTANCE_COUNT,
        VPCZoneIdentifier=setup_networking()["subnet2"],
    )

    return asg_client


class SimplisticTest(unittest.TestCase):

    @mock_autoscaling
    def test_find_asg(self):
        asg_client = init()
        self.assertEqual(len(find_asg_by_tag("k8s-test", asg_client)), 2)
        self.assertEqual(len(find_asg_by_tag("None", asg_client)), 0)
        self.assertEqual(len(find_asg_by_tag("", asg_client)), 0)


if __name__ == '__main__':
    unittest.main()
