package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// An example of how to test the simple Terraform module in examples/terraform-basic-example using Terratest.
func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete",
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	label8_tags := terraform.OutputMap(t, terraformOptions, "label8_tags")

  if assert.NotNil(t, label8_tags["cs:Owner"]) {
    assert.Equal(t, "john.smith+cicd@mail.com", label8_tags["cs:Owner"])
  }
  if assert.NotNil(t, label8_tags["cs:Attributes"]) {
    assert.Equal(t, "fire-water-earth-air", label8_tags["cs:Attributes"])
  }
}
