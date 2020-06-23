#!/usr/bin/make -f
SHELL=/bin/bash

HOSTS={debian,ubuntu,centos,amazon}
DNS_DOMAIN=demo.tonejito.cf

ANSIBLE_DIR=ansible
TERRAGRUNT_DIR=terraform/terragrunt

help:
	cat << EOF
	terragrunt-init    : Initialize terragrunt
	terragrunt-plan    : Plan terraform changes
	terragrunt-apply   : Apply terraform changes
	terragrunt-destroy : Delete terraform resources
	fping              : Ping VM's in parallel
	ansible-ping       : Check if ansible inventory is set up properly
	ansible-check      : Check if ansible playbook tasks are set up properly
	ansible-playbook   : Apply ansible provisioning
	EOF

terragrunt-plan:
	cd ${TERRAGRUNT_DIR} && \
	terragrunt plan

terragrunt-apply:
	cd ${TERRAGRUNT_DIR} && \
	terragrunt apply

terragrunt-destroy:
	cd ${TERRAGRUNT_DIR} && \
	terragrunt destroy

fping:
	fping -l ${HOSTS}.${DNS_DOMAIN}

nmap:
	nmap -v -oA nmap ${HOSTS}.${DNS_DOMAIN}

ssh-copy-id:
	echo ${HOSTS}.${DNS_DOMAIN} | xargs -t -n 1 -I {} ssh-copy-id -i ~/.ssh/id_rsa.pub tonejito@{}

ansible-ping:
	ansible -i ansible/inventory -m ping all

ansible-setup:
	ansible -i ansible/inventory -m setup all > ansible_setup.log

ansible-check:
	cd ${ANSIBLE_DIR} && \
	ansible-playbook -i inventory playbook.yaml --check

ansible-playbook:
	cd ${ANSIBLE_DIR} && \
	ansible-playbook -i inventory playbook.yaml
