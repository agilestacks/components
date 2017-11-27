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

