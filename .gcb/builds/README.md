# Terraform Build Configuration

This directory contains the Terraform configuration to provision the necessary Google Cloud resources to support the `google-cloud-dart` integration test builds. 

It assumes you have already created the remote state bucket as described in `../bootstrap/README.md`.

## Setup Instructions

1.  Ensure you have run the bootstrap step and that the backend state bucket `dart-sdk-testing-terraform` exists in your project.

2.  Change into this directory:
    ```shell
    cd .gcb/builds
    ```

3.  Initialize Terraform (this will configure the remote GCS backend):
    ```shell
    terraform init
    ```

4.  Preview the resources to be created:
    ```shell
    terraform plan -out /tmp/builds.tplan
    ```

5.  Apply the configuration:
    ```shell
    terraform apply /tmp/builds.tplan
    ```

## Resources Managed

The configuration is broken up into several modules:

-   `services`: Enables required Google Cloud APIs for testing (e.g., Storage, Secret Manager, AI Platform, etc.).
-   `resources`: Provisions integration testing resources, including the `dart-sdk-pool` worker pool.
-   `grants`: Configures IAM permissions for the integration test runner service account, ensuring it has adequate access to the testing resources.
-   `triggers`: Sets up the Google Cloud Build triggers attached to the GitHub repository. It defines triggers for pull requests, post-merge builds, and a periodic Terraform synchronization job.
