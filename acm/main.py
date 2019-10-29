#!/usr/bin/env python
"""Registers new ACM certificate and generates terraform for DNS approval

Usage:
  main.py request <domain> [<additional_names>]...
  main.py gen     <domain> [--standalone] [--save-to <filename>]
  main.py arn     <domain>
  main.py wait    <domain> [--timeout <sec>] [--status <status>]...
  main.py delete  <domain>

Options:
  -h --help            Show this screen.
  <domain>             Domain name associated to ACM certificate
  <additional_names>   Alternative domain names associated to ACM certificate (each must be approved separately)
  --standalone         Generate header for terraform to make it as standalone script
  --save-to <filename> To save generated terraform otherwise it will be printed to stdout
  --timeout <sec>      Timeout in seconds to wait for certificate (default 900)
  --status <status>    Break wait loop and exit when certificate will become in this status (can be multiple; default ISSUED)
"""

__author__ = "Antons Kranga"
__copyright__ = "Copyright 2017, Agile Stacks Inc."
__email__ = "anton@agilestacks.com"

terraform = '''#
# Generated for {{ cert_arn }}
#
{% if standalone: %}
terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

# upgrades must be tested as 2.x provider has a Route53 bug
# https://github.com/terraform-providers/terraform-provider-aws/issues/7918
provider "aws" {
  version = "1.60.0"
}

{% endif %}

{% for i,item in items %}
module "dns_{{ i }}" {
  source        = "github.com/agilestacks/terraform-modules//r53"
  name          = "{{ item['name'] }}"
  type          = "{{ item['type'] }}"
  r53_zone_id   = "{{ item['zone_id'] }}"
  r53_domain    = "{{ item['zone_name'] }}"
  records       = ["{{ item['record'] }}"]
  ttl           = "300"
}

{% endfor %}
'''

import boto3, sys, os, json, pprint, uuid, re, jsonschema, time
# from bson import json_util
import logging as log
from docopt  import docopt
from jinja2 import Template

log.basicConfig(filename='python.log', level=log.DEBUG)
console=log.StreamHandler() # intentionally log to stderr
console.setFormatter(log.Formatter(log.BASIC_FORMAT))
console.setLevel(log.WARNING)
log.getLogger().addHandler(console)

with open('acm-schema.json', 'r') as f:
    schema=json.loads( f.read().replace('\n', '') )

session = boto3.Session()
client  = session.client('acm')
r53     = session.client('route53')

def cert_by_domain(domain):
  response = client.list_certificates(
    CertificateStatuses=['PENDING_VALIDATION', 'ISSUED'],
    MaxItems=1000 # https://docs.aws.amazon.com/acm/latest/APIReference/API_ListCertificates.html
  )
  arns = [ c.get('CertificateArn') for c in response.get('CertificateSummaryList', []) if c.get('DomainName') == domain ]
  if not arns:
    return None
  if len(arns) > 1:
    log.warning("Certificate for %s has multiple instances, using first one", domain)
  return cert_by_arn(arns[0])

def render_terraform(cert, standalone=False):
  domains = cert.get('Certificate', {}).get('DomainValidationOptions', [])
  items = []
  for cert_alt_name in domains:
    cert_rec  = cert_alt_name['ResourceRecord']
    zone      = most_narrow_hosted_zone( cert_rec['Name'] )
    zone_name = zone['Name']
    pattern   = '(\.)?' + zone_name.replace('.', '\.') + '(\.)?$'
    domain    = cert_rec['Name'] if cert_rec['Name'][-1] == '.' else cert_rec['Name'] + '.'

    items.append({
      'name':      re.sub(pattern, '', domain),
      'record':    cert_rec['Value'],
      'type':      cert_rec['Type'],
      'zone_id':   zone['Id'].split('/')[-1],
      'zone_name': zone_name
    })

  log.info('DNS records for cert approve: %s', items)
  template = Template(terraform)
  return template.render(
      items=enumerate( items ),
      standalone=standalone,
      cert_arn=cert.get('Certificate', {}).get('CertificateArn')
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

def additional_names_match(cert, domain, requested_additional_names=[]):
  cert_additional_names = cert['Certificate'].get('SubjectAlternativeNames', [])
  for name in requested_additional_names:
    if name not in cert_additional_names:
      return (False, 'Existing ACM certificate {} subject alternative names:\n\t{}\ndoes not match requested names:\n\t{}'.format(
          domain, cert_additional_names, requested_additional_names))
  return True, None

# wait until certificate will conform to json schema
def wait_to_propogate(arn):
  print("Wait for certificate {} to propagate ".format(arn))
  for _ in range(60):
    cert = cert_by_arn(arn)
    if valid(cert, schema):
      print(' done')
      return cert
    time.sleep(3)
    sys.stdout.write('.')
  raise Exception('Timed out to propogate ACM DNS records to approve: {}'.format(arn))

def delete_certificate(cert):
  return client.delete_certificate(
    CertificateArn=cert['Certificate']['CertificateArn']
  )

def most_narrow_hosted_zone(name):
  parts = list(filter(None, name.split('.') ))
  size = len(parts)
  for i in range( size ):
    domain = '.'.join( parts[i:size] ) + '.'
    # TODO implement pagination if 100 zones is not enough
    resp = r53.list_hosted_zones_by_name(DNSName=domain, MaxItems='100')

    for hostedZone in resp.get('HostedZones', []):
      zname   = hostedZone.get('Name')
      zpublic = not hostedZone.get('Config', {'PrivateZone': True})['PrivateZone']
      if zname == domain and zpublic:
        return hostedZone

  raise Exception('Cannot find hosted zone that corresponds to {}'.format(name))

## does json schema validation
def valid(msg, schema):
  try:
    jsonschema.Draft3Validator(schema).validate(msg)
  except jsonschema.ValidationError as e:
    return False
  return True

if __name__ == "__main__":
  args = docopt(__doc__, version='ACM Controller 1.0')
  domain = args['<domain>']
  cert = cert_by_domain( domain )
  if cert:
    arn  = cert['Certificate']['CertificateArn']
  # print(json.dumps(cert, sort_keys=True, indent=4, separators=(',', ': '), default=json_util.default))

  if args['request']:
    additional_names = args['<additional_names>']
    if not cert:
      cert = request_certificate(domain, additional_names)
    else:
      log.warning("Certificate for %s already requested", domain)
      log.info("Certificate: %s", cert['Certificate'])
      match, err = additional_names_match(cert, domain, additional_names)
      if not match:
        raise Exception(err)

  elif args['gen']:
    if cert != None:
      tf = render_terraform( cert, args['--standalone'])
      if args['--save-to']:
        with open(args['--save-to'], "w") as f:
          f.write(tf)
        print('Done!')
      else:
        print(tf)

  elif args['delete']:
    if cert != None:
      resp = delete_certificate( cert )
      log.debug('Deleted certificate: %s', resp)
      print('Done!')
    else:
      log.warning("Certificate for %s has not been found", domain)

  elif args['arn']:
    if cert != None:
      print(cert['Certificate']['CertificateArn'])
    else:
      raise Exception('Cannot find ACM certificate for: {}'.format(domain))
  elif args['wait']:
    if cert != None:
      timeout = time.time() + int( args.get('<timeout>', 900) )
      desired = args.get('<status>', [])
      if not desired:
        desired = ['ISSUED']

      print('Wait {} until in status {}'.format(arn, desired))
      while (time.time() < timeout ):
        cert = cert_by_domain( domain )
        status = cert.get('Certificate', {}).get('Status', None)
        if status in desired:
          print('Done!')
          exit(0)
        time.sleep(10)
        print("Certificate is {}, {} sec, retry...".format(status, int(timeout - time.time())))
      raise Exception('Timeout waiting {} to become in status {}'.format(arn, desired))
    else:
      raise Exception('Cannot find ACM certificate for: {}'.format(domain))
