#!/usr/bin/env python
"""Registers new ACM certificate and generates terraform for DNS approval

Usage:
  main.py request <domain> [<additional_names>]... 
  main.py gen     <domain> --zone <domain> [--standalone] [--save-to <filename>]
  main.py arn     <domain>
  main.py delete  <domain>

Options:
  -h --help            Show this screen.
  <domain>             Domain name associated to ACM certificate
  <additional_names>   Alternative domain names associated to ACM certificate (each must be approved separately)
  --standalone         Generate header for terraform to make it as standalone script
  --zone <domain>      Domain name that corresponds to the hosted zone where DNS records shall be created
  --save-to <filename> To save generated terraform otherwise it will be printed to stdout
"""

__author__ = "Antons Kranga"
__copyright__ = "Copyright 2017, Agile Stacks Inc."
__email__ = "anton@agilestacks.com"

terraform = '''#
# Generated for ACM certificate: {{ domain }}
#
{% if standalone: %}
terraform {
  required_version = ">= 0.9.3"
  backend "s3" {}
}

provider "aws" {}

{% endif %}
data "aws_route53_zone" "{{ snake }}" {
  name  = "{{ domain }}"
}

{% for i,cname in items %}
module "dns_{{ i }}" {
  source        = "github.com/agilestacks/terraform-modules//r53"
  name          = "{{ cname['name'] }}"
  type          = "{{ cname['type'] }}"
  r53_zone_id   = "${data.aws_route53_zone.{{ snake }}.zone_id}"
  r53_domain    = "${data.aws_route53_zone.{{ snake }}.name}"
  records       = ["{{ cname['record'] }}"]
  ttl           = "300"
}

{% endfor %}
'''

import boto3, os, json, pprint, uuid, re, jsonschema, time
# from bson import json_util
import logging as log
from docopt  import docopt
from jinja2 import Template

log.basicConfig(filename='python.log', level=log.DEBUG)


with open('acm-schema.json', 'r') as f:
    schema=json.loads( f.read().replace('\n', '') )

session = boto3.Session()
client  = session.client('acm')


def cert_by_domain(domain):
  response = client.list_certificates(
    CertificateStatuses=['PENDING_VALIDATION', 'ISSUED'],
    MaxItems=99
  )
  arns = [ c.get('CertificateArn') for c in response.get('CertificateSummaryList',[]) if c.get('DomainName') == domain ]
  return cert_by_arn(arns[0]) if arns else None


def render_terraform(cert, zone_domain, standalone=False):
  domains = cert.get('Certificate', {}).get('DomainValidationOptions', [])
  pattern = '(\.)?' + zone_domain.replace('.', '\.') + '$'
  cnames = [
    { 
      'name':   re.sub(pattern, '', dom['ResourceRecord']['Name']),
      'record': dom['ResourceRecord']['Value'],
      'type':   dom['ResourceRecord']['Type']
    } for dom in domains
  ]
  print pattern
  log.info('DNS records for cert approve: %s', cnames)
  template = Template(terraform)
  return template.render(
      domain=zone_domain,
      items=enumerate( cnames ),
      standalone=standalone,
      snake=re.sub(r'[\.-]', '_', zone_domain)
    )

def cert_by_arn(arn):
  cert = client.describe_certificate(
    CertificateArn=arn
  )
  log.debug('Received certificate: %s', cert)
  return cert


def request_certificate(domain, additional_names=[]):
  log.info('Requesting a new certificate for %s', domain)
  if len(additional_names) == 0:
    response = response = client.request_certificate(
      DomainName=domain,
      ValidationMethod='DNS'
    )
  else:
    response = client.request_certificate(
      DomainName=domain,
      ValidationMethod='DNS',
      SubjectAlternativeNames=additional_names,
    )
  cert = wait_to_propogate( response['CertificateArn'] )
  return cert
  
# wait until certificate will conform to json schema
def wait_to_propogate(arn):
  for _ in range(60):
    cert = cert_by_arn(arn)
    if valid(cert, schema):
      return cert
    time.sleep(3)
    print "Wait for certificate {} to propogate".format(arn)
  raise Exception('Timed out to propogate ACM DNS records to approve: {}'.format(arn))

def delete_certificate(cert):
  return client.delete_certificate(
    CertificateArn=cert['Certificate']['CertificateArn']
  )

## does json schema validation
def valid(msg, schema):
  try:
    jsonschema.Draft3Validator(schema).validate(msg)
  except jsonschema.ValidationError as e:
    return False
  return True

if __name__ == "__main__":
  args = docopt(__doc__, version='ACM Controller 1.0')
  log.info('Arguments: %s', args)
  cert = cert_by_domain( args['<domain>'] )
  # print json.dumps(cert, sort_keys=True, indent=4, separators=(',', ': '), default=json_util.default)

  if args['request']:
    if not cert:
      cert = request_certificate( args['<domain>'], args['<additional_names>'] )
    else:
      log.warn("Certificate for %s already requested, see details %s", args['<domain>'], cert)
 
  elif args['gen']:    
    if cert != None:
      tf = render_terraform( cert, args['--zone'], args['--standalone'])
      if args['--save-to']:
        with open(args['--save-to'], "w") as f:
          f.write(tf)
        print 'Done!'
      else:
        print tf

  elif args['delete']:
    if cert != None:
      resp = delete_certificate( cert )
      log.debug('Deleted certificate: %s', resp)
      print 'Done!'
    else:
      log.warn("Certificate for %s has not been found", args['<domain>'])

  elif args['arn']:
    if cert != None:
      print cert['Certificate']['CertificateArn']
    else:
      raise Exception('Cannot find ACM certificate for: {}'.format(args['<domain>']))

