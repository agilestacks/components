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


def find_asg_by_tag(tag, asg_client=asg_client):
    asg_obj_list = asg_client.describe_auto_scaling_groups()["AutoScalingGroups"]
    data = []
    for asg_obj in asg_obj_list:
        belongs_to_cluster = any(x for x in asg_obj['Tags'] if "k8s.io/node-pool/"+tag in x["Key"])
        is_workers_asg = any(x for x in asg_obj['Tags'] if "worker" in x["Value"])
        if belongs_to_cluster and is_workers_asg:
            data.append(asg_obj['AutoScalingGroupName'])
    log.info("ASGs containig tag '{}': {}".format(tag, data))
    return data


def get_asg_hooks(asg_name, hook_name, asg_client=asg_client):
    resp = asg_client.describe_lifecycle_hooks(
        AutoScalingGroupName=asg_name,
        LifecycleHookNames=[hook_name]
    )["LifecycleHooks"]
    return resp[0] if len(resp) else []


def put_asg_hook(asg_name, hook_name, timeout, asg_client=asg_client):
    resp = asg_client.put_lifecycle_hook(
        LifecycleHookName=hook_name,
        AutoScalingGroupName=asg_name,
        LifecycleTransition='autoscaling:EC2_INSTANCE_TERMINATING',
        HeartbeatTimeout=timeout,
        DefaultResult='CONTINUE'
    )
    return resp


def handler(event, context):
    domain_name = os.environ['DOMAIN_NAME']

    if not valid(domain_name):
        raise Exception('This lambda requires env variable `DOMAIN_NAME`, instead it got: {}'.format(domain_name))

    #log.info("Incoming event: %s", json.dumps(event, indent=2))
    log.info("Incoming event: {}".format(event["detail-type"]))

    asg_name = event['detail']['AutoScalingGroupName']
    log.info("ASG name: '{}'".format(asg_name))
    log.info("Cluster name: '{}'".format(domain_name))

    asg_list = find_asg_by_tag(domain_name)
    if len(asg_list) == 0:
        log.info("ASG doesn't contain cluster name: {} - skipping".format(str(len(asg_list))))
        return
    for asg in asg_list:
        if len(get_asg_hooks(asg, NODE_DRAINER_HOOK_NAME)) == 0:
            log.info("Adding hook '{}' to ASG: {}".format(NODE_DRAINER_HOOK_NAME, asg))
            return put_asg_hook(asg, NODE_DRAINER_HOOK_NAME, NODE_DRAINER_TIMEOUT)
        else:
            log.info("ASG: {} contains already hook: {} - skipping".format(asg, NODE_DRAINER_HOOK_NAME))
