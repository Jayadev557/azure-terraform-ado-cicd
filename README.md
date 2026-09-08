# Azure DevOps + Terraform CI/CD — Learning Notes

## 1. Project Structure

```text
proj_infra_001/
│
├── environment/
│   ├── preprod/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfvars
│   │   └── variable.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── provider.tf
│       ├── terraform.tfvars
│       └── variable.tf
│
├── module/
│   ├── azurerm_resource_group/
│   │   ├── main.tf
│   │   └── variable.tf
│   │
│   └── azurerm_storage_account/
│       ├── main.tf
│       └── variable.tf
│
└── pipelines/
    └── azure-pipelines.yml
```

Pipeline YAML ko Git repository mein rakhna better hai because pipeline configuration bhi version-controlled rahegi.

---

# 2. Branching Strategy

Learning project mein feature branch + PR flow use kiya:

```text
feature/terraform-pipeline
            ↓
          PR
            ↓
           main
```

PR create karne se pehle feature branch par changes commit/push:

```powershell
git add .
git commit -m "Update pipeline"
git push origin feature/terraform-pipeline
```

---

# 3. Azure DevOps Setup

### Service Connection

Service connection:

```text
jdpipeline
```

Authentication:

```text
Workload Identity Federation
```

### Agent

Self-hosted Windows agent:

```text
Pool: jdpipelinepool
```

Agent machine par required tools installed:

```text
Terraform 1.12.2
Azure CLI 2.89.0
Checkov 3.2.450
Git 2.41.0
```

### Environment

ADO Environment:

```text
terraform-preprod
```

Is environment par approval configured kiya gaya.

---

# 4. PR Branch Policy

`main` branch par branch policy configure ki:

```text
Require PR
Build Validation
Approver required
```

Iska purpose:

```text
Feature branch → PR → Validation → Approval → Merge
```

PR validation successful hue bina main mein merge allowed nahi hoga.

---

# 5. Terraform Backend

Terraform state Azure Storage Account mein store kiya:

```hcl
backend "azurerm" {
  resource_group_name  = "backend-rg-donot-delete"
  storage_account_name = "pipelinestg001"
  container_name       = "pipcontainer"
  key                  = "preprod.terraform.tfstate"
}
```

Important:

Terraform state ko Git mein commit nahi karna chahiye.

---

# 6. First Major Error — Backend 403

Error:

```text
403 Forbidden

does not have authorization to perform action:
Microsoft.Storage/storageAccounts/read
```

### Cause

ADO service connection ki identity ko backend Storage Account read karne ki permission nahi thi.

### Fix

Service connection ki identity ko appropriate Azure RBAC permission di.

Backend storage ke liye required access ensure kiya.

---

# 7. Second Major Error — Resource Group 403

Error:

```text
does not have authorization to perform action:
Microsoft.Resources/subscriptions/resourceGroups/read
```

Identity/Object ID:

```text
3412fc7b-250e-42b8-b92b-00da9d9fd644
```

### Cause

Pipeline ki service principal identity ke paas Resource Group ko read/create/manage karne ki required permission nahi thi.

### Fix

Azure Subscription ke IAM mein service connection identity ko:

```text
Role: Contributor
Scope: Subscription
```

diya.

RBAC propagation ke baad pipeline rerun ki.

---

# 8. Checkov Security Scan

Initially Checkov mein multiple failures aaye.

Example:

```text
CKV2_AZURE_1
CKV_AZURE_59
CKV_AZURE_33
CKV_AZURE_206
CKV2_AZURE_40
CKV2_AZURE_33
CKV2_AZURE_41
```

Ye mostly production-level security recommendations the, jaise:

* Customer Managed Key
* Private Endpoint
* Storage logging
* Replication
* Shared Key restriction
* SAS expiration policy
* Public access restriction

Learning project ke scope mein sab implement karna unnecessary tha.

---

# 9. Terraform Storage Account Security Improvements

Storage Account module mein practical security settings add ki:

```hcl
min_tls_version                 = "TLS1_2"
allow_nested_items_to_be_public = false

blob_properties {
  delete_retention_policy {
    days = 7
  }

  container_delete_retention_policy {
    days = 7
  }
}
```

Isse kuch Checkov checks pass hue.

---

# 10. Checkov Exceptions

Learning project ke liye intentionally unsupported checks ko pipeline command mein skip kiya:

```powershell
checkov -d . --skip-check CKV2_AZURE_1,CKV_AZURE_59,CKV_AZURE_33,CKV_AZURE_206,CKV2_AZURE_40,CKV2_AZURE_33,CKV2_AZURE_41
```

Important:

Checkov skip ka matlab security issue solve karna nahi hai.

Ye sirf:

```text
"Known exception for this learning project"
```

ke liye hai.

Production project mein proper justification + actual remediation preferred hai.

---

# 11. Terraform Formatting

Pipeline/local validation se pehle:

```powershell
terraform fmt -recursive
```

Isse Terraform files automatically standard format mein aa gayi.

---

# 12. Local Checkov Validation

Final local scan:

```powershell
checkov -d . --skip-check CKV2_AZURE_1,CKV_AZURE_59,CKV_AZURE_33,CKV_AZURE_206,CKV2_AZURE_40,CKV2_AZURE_33,CKV2_AZURE_41
```

Result:

```text
Terraform:
Passed checks: 8
Failed checks: 0

Azure Pipelines:
Passed checks: 2
Failed checks: 0
```

Therefore local security validation successful.

---

# 13. Final Git Flow

Changes ko feature branch par commit kiya:

```powershell
git status
git add .
git commit -m "Update Checkov security validation"
git push origin feature/terraform-pipeline
```

Then:

```text
feature/terraform-pipeline
          ↓
          PR
          ↓
   Build Validation
          ↓
        Approval
          ↓
       Merge main
```

---

# 14. Final CI/CD Flow

Final pipeline architecture:

```text
Developer
   ↓
Feature Branch
   ↓
Push Code
   ↓
Create PR
   ↓
Build Validation
   ├── Terraform fmt
   ├── Terraform init
   ├── Terraform validate
   ├── Checkov scan
   └── Terraform plan
   ↓
PR Approval
   ↓
Merge to main
   ↓
Deploy Pipeline
   ↓
terraform-preprod Environment
   ↓
Manual Approval
   ↓
Terraform Apply
   ↓
Azure Resources
```

---

# 15. Important Troubleshooting Lessons

### 403 AuthorizationFailed

Always check:

```text
Which identity is Terraform using?
        ↓
Service Connection
        ↓
Object ID
        ↓
Azure IAM role
        ↓
Scope
```

Role assignment sirf naam dekh kar assume nahi karna.

Check exact scope:

```text
Subscription
Resource Group
Storage Account
```

---

### Terraform backend error

Agar `terraform init` mein Storage Account 403 aaye:

```text
Microsoft.Storage/storageAccounts/read
```

toh backend storage par service connection identity ki permission check karo.

---

### Resource Group error

Agar:

```text
Microsoft.Resources/subscriptions/resourceGroups/read
```

aaye, toh Azure subscription/resource-group level RBAC check karo.

---

### Checkov failure

Har Checkov failure ko blindly skip nahi karna.

Process:

```text
Checkov failure
      ↓
Understand policy
      ↓
Can we fix it?
      ↓
YES → Terraform configuration improve
      ↓
NO / Not required for learning scope
      ↓
Documented skip
```

---

# 16. Final Learning

Is project se following concepts practically cover hue:

* Git feature branching
* PR-based development
* Branch policies
* Build validation
* Azure DevOps YAML pipelines
* Self-hosted agent
* Azure Service Connection
* Workload Identity Federation
* Azure RBAC
* Terraform modules
* Terraform backend
* Terraform init
* Terraform validate
* Terraform plan
* Terraform apply
* Checkov security scanning
* ADO Environment
* Manual approvals
* CI/CD workflow
* Troubleshooting 403 authorization errors

**Final principle:**

```text
Code → Validate → Scan → Plan → Review → Approve → Merge → Deploy → Apply
```

Ye flow Infrastructure-as-Code ke liye ek solid learning-level CI/CD foundation hai.
