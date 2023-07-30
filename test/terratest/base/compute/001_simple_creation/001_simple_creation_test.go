package test


import (
	"fmt"
	"strings"
	"testing"
	"time"
	"os"
	"log"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformHelloWorldExample(t *testing.T) {
	t.Parallel()

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "/workdir/test/base/compute/001_simple_creation",
		VarFiles: []string{
			// "/workdir/test/base/compute/000_shared/test_credentials.tfvars",
			"/workdir/test/base/compute/001_simple_creation/test.tfvars",
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Get the public IP address of the deployed instance
	publicInstanceIP := terraform.Output(t, terraformOptions, "public_ip")

	// Create an SSH key pair struct with the private key location
	priv, err := os.ReadFile("/workdir/emergency-user-key")
    if err != nil {
        log.Fatal(err)
    }
	pub, err := os.ReadFile("/workdir/emergency-user-key.pub")
    if err != nil {
        log.Fatal(err)
    }

	keyPair := ssh.KeyPair{
		PrivateKey: string(priv),
		PublicKey: string(pub),
	}

	publicHost := ssh.Host{
		Hostname:    publicInstanceIP,
		SshKeyPair:  &keyPair,
		SshUserName: "emergency",
	}

	maxRetries := 6
	timeBetweenRetries := 5 * time.Second
	description := fmt.Sprintf("SSH to public host %s", publicInstanceIP)

	// Run a simple echo command on the server
	expectedText := "Hello, World"
	command := fmt.Sprintf("echo -n '%s'", expectedText)

	// Verify that we can SSH to the Instance and run commands
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {
		actualText, err := ssh.CheckSshCommandE(t, publicHost, command)

		if err != nil {
			return "", err
		}

		if strings.TrimSpace(actualText) != expectedText {
			return "", fmt.Errorf("Expected SSH command to return '%s' but got '%s'", expectedText, actualText)
		}

		return "", nil
	})

	// Run a command on the server that results in an error,
	expectedText = "Hello, World"
	command = fmt.Sprintf("echo -n '%s' && exit 1", expectedText)
	description = fmt.Sprintf("SSH to public host %s with error command", publicInstanceIP)

	// Verify that we can SSH to the Instance, run the command and see the output
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {

		actualText, err := ssh.CheckSshCommandE(t, publicHost, command)

		if err == nil {
			return "", fmt.Errorf("Expected SSH command to return an error but got none")
		}

		if strings.TrimSpace(actualText) != expectedText {
			return "", fmt.Errorf("Expected SSH command to return '%s' but got '%s'", expectedText, actualText)
		}

		return "", nil
	})
	
}

