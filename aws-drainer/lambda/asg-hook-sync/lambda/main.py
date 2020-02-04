import os, sys

script_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, script_dir + os.sep + "lib")

import json, boto3

import logging

log = logging.getLogger()
log.setLevel(logging.INFO)

session = boto3.Session()
asg_client = session.client('autoscaling')

NODE_DRAINER_HOOK_NAME = "aws-node-drainer"
NODE_DRAINER_TIMEOUT = 180


def valid(name):
    if name and name.strip():
        return True
    else:
        return False

def asg_contains_tag(asg_name, cluster_name):
  resp = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])['Tags']
  return any(x for x in resp if cluster_name in x.key)

def describe_asg_hooks(asg_name, hook_name):
    resp = asg_client.describe_lifecycle_hooks(
        AutoScalingGroupNames=[asg_name],
        LifecycleHookNames=[hook_name]
    )
    return resp[0] if len(resp) else []


def put_hook(asg_name, hook_name, timeout):
    resp = asg_client.put_lifecycle_hook(
        LifecycleHookName=hook_name,
        AutoScalingGroupName=asg_name,
        LifecycleTransition='autoscaling:EC2_INSTANCE_TERMINATING',
        HeartbeatTimeout=timeout,
        DefaultResult='CONTINUE'
    )
    return resp


def handler(event, context):
    cluster_name = os.environ['CLUSTER_NAME']

    if not valid(cluster_name):
        raise Exception('This lambda requires env variable `CLUSTER_NAME`, instead it got: {}'.format(cluster_name))

    log.info("Incoming event: %s", json.dumps(event, indent=2))
    asg_name = event['detail']['AutoScalingGroupName']

    if not asg_contains_tag(asg_name, cluster_name):
        log.info("ASG doesn't contain cluster name - skipping")
        return
    
    asg_obj_hook = describe_asg_hooks(asg_name, NODE_DRAINER_HOOK_NAME)

    if len(asg_obj_hook) == 0:
        return put_hook(asg_name, NODE_DRAINER_HOOK_NAME, NODE_DRAINER_TIMEOUT)
    else:
        log.info("ASG: {} contains already hook: {} - skipping".format(asg_name, NODE_DRAINER_HOOK_NAME))
