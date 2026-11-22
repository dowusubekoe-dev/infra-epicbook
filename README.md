# EpicBook on Azure — Terraform Infrastructure

Terraform configuration that provisions the Microsoft Azure infrastructure for the EpicBook bookstore application, with an Azure DevOps pipeline to run it.

> **Project context:** Built during the Cloud DevOps Bootcamp (The CloudAdvisory Oy, 2026) as the infrastructure half of a two-repository deployment. The companion repository [prod-grade-epicbook-terraform-ansible-roles-aws](https://github.com/dowusubekoe-dev/prod-grade-epicbook-terraform-ansible-roles-aws) configures the server and deploys the application with Ansible roles. (Despite the word "aws" in that repo's historical name, the deployment target is Azure.)

## What this repo provisions

Using the `azurerm` provider (~> 3.100, Terraform >= 1.5):

- Resource group for all project resources
- Virtual network (10.0.0.0/16) with a web subnet (10.0.1.0/24) and a delegated MySQL subnet
- Network security group for the VM
- Ubuntu Linux virtual machine with a public IP (the web/application server)
- Azure Database for MySQL Flexible Server, reachable only from inside the virtual network, with a randomised name suffix

State is stored remotely in an Azure Storage **azurerm backend** (`backend.tf`), so the pipeline and local runs share one state.

## Repository structure

```
├── main.tf            # Resource group, VNet, subnets, NSG, VM, MySQL Flexible Server
├── variables.tf       # Input variables (prefix, location, VM size, credentials)
├── outputs.tf         # Outputs consumed by the Ansible stage (VM address, endpoints)
├── backend.tf         # Remote state in Azure Storage
└── azure-pipelines.yml # Azure DevOps pipeline: init → plan → apply, publishes outputs
```

## How it runs

- **Pipeline:** `azure-pipelines.yml` runs on a self-hosted agent pool, authenticates to Azure through a service connection, supplies the SSH public key as a secure file, and runs Terraform init/plan/apply. On completion it publishes the Terraform outputs as the `infra-outputs` artifact, which triggers the Ansible pipeline in the companion repo.
- **Manually:**

  ```bash
  terraform init
  terraform plan -var-file="terraform.tfvars"
  terraform apply -var-file="terraform.tfvars"
  ```

  Variable values (including the MySQL admin password and SSH key) go in a local `terraform.tfvars`, which is git-ignored and never committed.

## Skills demonstrated

Terraform (azurerm) infrastructure as code, remote state management, Azure networking (VNet, subnets, NSG, delegated subnets), Azure Database for MySQL Flexible Server, Azure DevOps YAML pipelines with service connections and secure files, and a two-stage provision-then-configure deployment design.
