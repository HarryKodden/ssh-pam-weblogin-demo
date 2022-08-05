# Demo Docker sandbox for SSH + PAM Weblogin

# Docker for sandbox development

You can develop the module in a sandbox envrionment. This sandbox environment contains all dependencies needed for compilation and testing the module.

## Prepare **env/ldap.env**

Copy or rename the sample env/ldap.env.sample to env/ldap.env and adjust the values as indicated

## Prepare **env/pam.env**

Copy or rename the sample env/pam.env.sample to env/pam.env and adjust the values as indicated

## Start docker environment

```
docker-compose up
```

Now ssh into the container via:

```
ssh -p 2222 <user>@localhost
```

Where user is the SRAM uid of a member of a collaboration having this service linked.

TO BE COMPLETED !
