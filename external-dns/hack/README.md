# Hack

Files in this directory will override files in the helm chart. It's content (with subdirectories) actually repeats one in the helmchart

## Change history

Here we replicate change history. So, it would be easier to patch files in the future.

### _helpers.tmpl

Following code has been introduced. We want to trely on EC2InstanceMetadata (if cloud kind: `aws`) when assuming role from instance profile.

```shell
{{- define "external-dns.aws-config" }}
[profile default]
region = {{ .Values.aws.region }}
# source_profile = default
credential_source = Ec2InstanceMetadata
role_arn={{ .Values.aws.assumeRoleArn }}
{{ end }}
```
