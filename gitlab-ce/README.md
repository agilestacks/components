# GitLab CE Component for Agilestacks Automation Hub


## Dependencies

This component dependes on the Agilestacks `postgres` component. 

## Configuration

#### Parameters : 
* name:    name default: gitlab-ce
* name:    namespace default: gitlab
* name:    dbHost default: "" ## IMPORTANT if this is set, it will point gitlab to an external host instead of the local PG
* name:    dbName default: gitlab
* name:    dbNassword default: supersecret
* name:    database default: gitlab
* name:    volume default: 8Gi
* name:    port default: 80

#### Required External Parameters : 

This component leverages the admin user/pass from `postgres` in order to create it's own gitlab specific user and password. 

It leverages several parameters defined for `postgres` including : 

* component.postgresql.user
* component.postgresql.password
* component.postgresql.database
* component.postgresql.url

If the `url` is not supplied,  it will guess the url by synthesizing the postgres service name and namespace. 

This also leverages traefk-acm and the kubernetes OCDC Issuer (Dex) 

* name: component.ingress.fqdn
* name: component.ingress.ssoUrlPrefix
* name: component.ingress.protocol
* name: component.dex.issuer

* This also currently needs to register its own ELB for the `git` subdomain. So it also requires. 

* name: component.gitlab-ce.acm_certificate.arn - this is retrieved by default from ACM_CERTIFICATE_ARN


# GitLab Community Edition

[GitLab Community Edition](https://about.gitlab.com/) is an application to code, test, and deploy code together. It provides Git repository management with fine grained access controls, code reviews, issue tracking, activity feeds, wikis, and continuous integration. 

## Introduction

This chart stands up a GitLab Community Edition install. This includes:

- A [GitLab Omnibus](https://docs.gitlab.com/omnibus/) Pod
- Redis

## Prerequisites

- _At least_ 3 GB of RAM available on your cluster, in chunks of 1 GB
- Kubernetes 1.6
- PV provisioner support in the underlying infrastructure
- The ability to point a DNS entry or URL at your GitLab install

## Persistence

By default, persistence of GitLab data and configuration happens using PVCs. If you know that you'll need a larger amount of space, make _sure_ to look at the `persistence` section in [values.yaml](values.yaml).

> *"If you disable persistence, the contents of your volume(s) will only last as long as the Pod does. Upgrading or changing certain settings may lead to data loss without persistence."*
