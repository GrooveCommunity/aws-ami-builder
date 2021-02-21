# AWS AMI Builder

A GitHub Workflow automation repository to build AWS AMIs from Packer template files pushed to the **main** branch.

- [:file_folder: templates/](templates/) - Packer templates, only HCL2 allowed.
- [:file_folder: playbooks/](playbooks/) - Ansible playbooks and roles.
- [:file_folder: .github/workflows/](.github/workflows/) - Workflow (pipeline as code) for each AMI build.


Environment **"unstable"** is used used to approve releases from **main** branch workflows.

- :rocket: **Deployment reviewers:**
  - [@cloyol1](https://github.com/cloyol1)
  - [@codermarcos](https://github.com/codermarcos)
  - [@vflopes](https://github.com/vflopes)

## Available AMIs

- [debian-10-amd64-cis](templates/debian-10-amd64-cis.pkr.hcl)
  - **OS:** Debian
  - **Version:** 10 (Buster)
  - **Hardening:** PCI-DSS compliant, [cisecurity.org] (thanks to [ovh/debian-cis](https://github.com/ovh/debian-cis))
  - **Includes:**
    - git (stable)
    - ansible 3.0.0
  - **Artifacts:**
    - :page_facing_up: `debian-cis-apply.log` - Hardening scripts log output.
    - :page_facing_up: `debian-cis-audit-all.log` - Auditing log output (post-apply execution).