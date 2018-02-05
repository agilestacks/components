# ACM certificate

This component creates DNS approved ACM certificates. Becasue this is quite new functionality, author was only able to find `boto3` that supports it (neither CLI neither any other `aws-sdk` supports it at November 2017).

This is why we implemented it in python.

## Configure AWS credentials

We rely on environment variables (for instance `AWS_DEFAULT_REGION`, `AWS_PROFILE`) see details here: http://boto3.readthedocs.io/en/latest/guide/configuration.html#environment-variable-configuration

## How to use it

For precise syntax instructions follow `main.py -h` or read `Makefile`

1. Run `main.py request <domain_names>`  that will request a certificate 
2. Run `main.py gen <domain_name> ...` to generate terraform scrit
3. Apply terraform script

## Automation Hub

Python control script has been incapsulated with `Makefile` `deploy` and `undeploy` verbs.
* `deploy`: It creates a new ACM instance, generates validation records for Route 53 (detects most narrow Route 53 hosted zone) in your cloud account and then run terrafor mscripts
* `Undeploy`: Deletes Route53 validation records however leaves `ACM` certificate intact (To respect AWS limit: Number of ACM certificates during last 365 days). This behaviour can be customized with:
```yaml
parameters:
- name: component.acm.deleteCert
  value: true
```

