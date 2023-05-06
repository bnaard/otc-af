


# OTC-AF Base Compute Terraform Project

This is an open source project for creating a base compute infrastructure on OTC-AF using Terraform. This project aims to automate the creation and management of compute instances on OTC-AF, providing a solid base for any application that needs to be deployed in the cloud.

## Getting Started

To get started with this project, you will need to have Terraform installed on your machine. You can download the latest version of Terraform from the official website: https://www.terraform.io/downloads.html.

Once you have Terraform installed, you can clone this repository to your local machine:

```
git clone https://github.com/bnaard/otc-af-base-compute.git
```

Next, navigate to the cloned repository and create a `terraform.tfvars` file with your OTC-AF credentials:

```
otc_access_key = "your-access-key"
otc_secret_key = "your-secret-key"
```

## Usage

To use this project, navigate to the cloned repository and run the following commands:

```
terraform init
terraform plan
terraform apply
```

The `terraform init` command will download the necessary provider plugins and modules. The `terraform plan` command will show you what Terraform plans to do before actually doing it. The `terraform apply` command will apply the changes to your OTC-AF account.

To destroy the infrastructure created by this project, run the following command:

```
terraform destroy
```

## Tests

This project includes automated tests to ensure the correctness of the Terraform code. To run the tests, you will need to have Docker installed on your machine.

To run the tests, navigate to the cloned repository and run the following commands:

```
docker build -t otc-af-base-compute .
docker run -v $(pwd):/code otc-af-base-compute
```

The first command will build a Docker image containing the necessary dependencies for running the tests. The second command will run the tests inside the Docker container.

The tests are located in the `tests` directory and are implemented using [Terratest](https://github.com/gruntwork-io/terratest). Terratest is a Go library that provides helpers for testing Terraform code.

## Contributing

We welcome contributions from the community. To contribute, please fork this repository and submit a pull request with your changes.

Before submitting a pull request, please make sure to run the tests and ensure that they pass. To run the tests locally, see the instructions in the "Tests" section of this README.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.