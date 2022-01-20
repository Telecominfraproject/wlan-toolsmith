## Usage
This playbook installs and configures the Ananda agent on the lab controllers to set them up as gateways.

You need to install the amazon.aws collection (requires Ansible version 2.9+) and it's dependencies before being able to run the playbook:
```
ansible-galaxy collection install amazon.aws
pip install botocore boto3
```


Since the Ananda tokens are saved as AWS Secrets you also have to login into the SSO account with id `289708231103`. It is required to set the following environment variables:
```
export AWS_PROFILE="AdministratorAccess-289708231103" # Depends on your chosen profile name
export AWS_DEFAULT_REGION="us-east-2"
```


Execute a dry-run with `ansible-playbook -i hosts.yml setup_gateways.yml --diff --check`.

Apply the changes with `ansible-playbook -i hosts.yml setup_gateways.yml --diff`.
