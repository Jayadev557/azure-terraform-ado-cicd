# Azure Terraform ADO CI/CD

This is a learning project to practice **Terraform, Azure, and Azure DevOps CI/CD pipelines**.

The project creates Azure infrastructure using reusable Terraform modules and deploys it through an Azure DevOps pipeline.

---

## Architecture

The basic CI/CD flow is:

```text
Developer
    |
    v
Feature Branch
    |
    v
Pull Request
    |
    v
Azure DevOps Build Validation
    |
    +-- Terraform Format
    +-- Terraform Init
    +-- Terraform Validate
    +-- Checkov Security Scan
    +-- Terraform Plan
    |
    v
PR Approval
    |
    v
Merge to main
    |
    v
Deployment Pipeline
    |
    v
Preprod Environment
    |
    v
Manual Approval
    |
    v
Terraform Apply
    |
    v
Azure Resources
```

### High-Level Components

```text
+----------------------+
|     Azure Repos      |
|                      |
| Feature Branch / PR  |
+----------+-----------+
           |
           v
+----------------------+
|    Azure Pipeline    |
|                      |
| fmt / init /         |
| validate / Checkov / |
| plan                 |
+----------+-----------+
           |
           v
+----------------------+
| Terraform-preprod    |
| Azure DevOps         |
| Environment          |
|                      |
| Manual Approval      |
+----------+-----------+
           |
           v
+----------------------+
|        Azure         |
|                      |
| Resource Group       |
| Storage Account      |
+----------------------+
```

---

## What I am Learning

* Terraform basics
* Terraform modules
* Terraform remote state
* Azure DevOps YAML pipelines
* Git feature branches
* Pull Requests
* Branch policies
* Terraform validation and planning
* Checkov security scanning
* Azure RBAC
* Azure DevOps Environments
* Manual approvals
* Terraform deployment
* CI/CD best practices

---

## Project Structure

```text
.
├── environment
│   ├── preprod
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfvars
│   │   └── variable.tf
│   │
│   └── prod
│       ├── main.tf
│       ├── provider.tf
│       ├── terraform.tfvars
│       └── variable.tf
│
├── module
│   ├── azurerm_resource_group
│   │   ├── main.tf
│   │   └── variable.tf
│   │
│   └── azurerm_storage_account
│       ├── main.tf
│       └── variable.tf
│
└── pipelines
    └── azure-pipelines.yml
```

---

## Terraform

The project uses reusable Terraform modules for:

* Azure Resource Group
* Azure Storage Account

Separate environment folders are used for:

* Preprod
* Prod

This keeps environment-specific configuration separate from reusable Terraform modules.

### Remote State

Terraform state is stored remotely in an Azure Storage Account using the AzureRM backend.

Example:

```hcl
backend "azurerm" {
  resource_group_name  = "backend-rg-donot-delete"
  storage_account_name = "pipelinestg001"
  container_name       = "pipcontainer"
  key                  = "preprod.terraform.tfstate"
}
```

Remote state helps keep Terraform state outside the Git repository.

---

## CI/CD Pipeline

The pipeline has two main stages.

### 1. Validation and Plan

This stage runs when code is validated through a Pull Request.

It performs:

```text
terraform fmt
        |
terraform init
        |
terraform validate
        |
Checkov scan
        |
terraform plan
```

The purpose is to catch formatting issues, Terraform errors, and security problems before merging code.

### 2. Deployment

After the Pull Request is approved and merged into `main`, the deployment stage runs.

The deployment uses the Azure DevOps environment:

```text
terraform-preprod
```

A manual approval is required before Terraform Apply.

```text
main
 |
 v
Deployment
 |
 v
terraform-preprod
 |
 v
Manual Approval
 |
 v
terraform apply
```

---

## Git Workflow

This project uses a feature branch workflow.

Example feature branch:

```text
feature/terraform-pipeline
```

After making changes:

```bash
git status

git add .

git commit -m "Update Terraform pipeline"

git push origin feature/terraform-pipeline
```

Then create a Pull Request:

```text
feature/terraform-pipeline
              |
              v
             PR
              |
              v
             main
```

The `main` branch has branch policies enabled.

The validation pipeline must pass before the Pull Request can be merged.

---

## Prerequisites

The following tools are required on the self-hosted agent:

* Git
* Terraform
* Azure CLI
* Checkov
* Azure DevOps self-hosted agent

Example versions used during this project:

```text
Terraform 1.12.2
Azure CLI 2.89.0
Checkov 3.2.450
Git 2.41.0
```

The versions may be different in another environment.

---

## Azure DevOps Configuration

The project uses the following Azure DevOps components:

```text
Agent Pool:
jdpipelinepool

Service Connection:
jdpipeline

Authentication:
Workload Identity Federation

Environment:
terraform-preprod
```

The service connection is used by Terraform to authenticate with Azure.

The Azure DevOps service connection identity must have the required Azure RBAC permissions.

---

## Deployment Steps

### Step 1 — Create Feature Branch

```bash
git checkout -b feature/my-change
```

### Step 2 — Make Terraform Changes

Update the required Terraform files.

### Step 3 — Format Terraform

```bash
terraform fmt -recursive
```

### Step 4 — Run Validation

```bash
terraform init
terraform validate
```

### Step 5 — Run Checkov

```bash
checkov -d .
```

If the project has documented exceptions:

```bash
checkov -d . --skip-check <CHECK_ID>
```

### Step 6 — Commit and Push

```bash
git add .

git commit -m "Update infrastructure"

git push origin feature/my-change
```

### Step 7 — Create Pull Request

Create a PR from:

```text
feature/my-change → main
```

The validation pipeline runs automatically.

### Step 8 — Review and Approve

Review the Terraform plan and pipeline results.

After approval, merge the PR into `main`.

### Step 9 — Deployment

The deployment pipeline starts for the configured environment.

The `terraform-preprod` environment requires manual approval.

After approval:

```text
terraform apply
```

runs and creates/updates the Azure infrastructure.

---

## Checkov Security Scan

Checkov is used to scan Terraform code for security issues.

Example:

```bash
checkov -d .
```

During this learning project, some checks were skipped because they represent production-level features that are outside the current project scope.

For example:

```text
CKV2_AZURE_1
CKV_AZURE_59
CKV_AZURE_33
CKV_AZURE_206
CKV2_AZURE_40
CKV2_AZURE_33
CKV2_AZURE_41
```

These exceptions should not automatically be used in production.

In a production project, the recommended approach is to understand and fix the security finding wherever possible.

---

## Azure RBAC Troubleshooting

One important issue faced during this project was:

```text
403 AuthorizationFailed
```

Example:

```text
does not have authorization to perform action
Microsoft.Resources/subscriptions/resourceGroups/read
```

### Cause

The Azure DevOps service connection identity did not have the required Azure permissions.

### Resolution

The service connection identity was given the required RBAC role at the appropriate scope.

For this learning project, `Contributor` access at the subscription scope was used.

Always check:

```text
Service Connection
       |
       v
Identity / Object ID
       |
       v
Azure IAM
       |
       v
Role
       |
       v
Scope
```

Also allow some time for Azure RBAC changes to propagate before rerunning the pipeline.

---

## Useful Troubleshooting Commands

Check the current Git branch:

```bash
git branch
```

Check Git status:

```bash
git status
```

Check remote branches:

```bash
git fetch origin
git branch -a
```

Check recent commits:

```bash
git log --oneline -5
```

Format Terraform:

```bash
terraform fmt -recursive
```

Validate Terraform:

```bash
terraform validate
```

Run Checkov:

```bash
checkov -d .
```

---

## Important Lessons

### 1. Pipeline YAML should be stored in Git

Keeping the pipeline YAML inside the repository provides:

* Version history
* Code review
* Change tracking
* Easy rollback

### 2. PR validation protects the main branch

Terraform changes should be validated before merging.

### 3. Plan and Apply should be controlled

`terraform plan` helps review infrastructure changes.

`terraform apply` should be protected with an approval process.

### 4. Azure RBAC matters

A successful service connection does not automatically mean Terraform has permission to access every Azure resource.

### 5. Security scans should be understood

Do not blindly skip Checkov failures.

First understand the finding and decide whether it should be fixed or documented as an exception.

---

## Current Project Status

The following flow has been successfully tested:

```text
Feature Branch
      ↓
Pull Request
      ↓
Build Validation
      ↓
Terraform fmt        ✅
Terraform init       ✅
Terraform validate   ✅
Checkov              ✅
Terraform plan       ✅
      ↓
PR Approval          ✅
      ↓
Merge to main        ✅
      ↓
Deployment           ✅
      ↓
Manual Approval      ✅
      ↓
Terraform Apply      ✅
      ↓
Azure Deployment     ✅
```

---

## Future Improvements

Possible next steps for this project:

* Separate CI and CD pipelines
* Proper Preprod and Prod deployment stages
* Separate Terraform state for each environment
* Terraform plan artifact
* Secure secrets management
* Azure Key Vault integration
* More Checkov findings fixed instead of skipped
* Private Endpoint implementation
* Customer Managed Key encryption
* Production-level RBAC
* Remote state locking and governance
* Deployment notifications

---

## Goal

The main goal of this project is to understand how Terraform infrastructure can be safely:

```text
Developed
   ↓
Validated
   ↓
Security Scanned
   ↓
Planned
   ↓
Reviewed
   ↓
Approved
   ↓
Deployed
```

This is a **learning project** and is not intended to be a production-ready infrastructure setup.
