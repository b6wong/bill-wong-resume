// Terraform does not have great support for Single Sign On yet.
// Right now when running locally, will need to go to SSO and copy/paste
// the session into the ~/.aws/credentials file, naming it "default" for now
// It is also assuming the role for the "playgound" account. This should
// be configured based on environment
provider "aws" {
  profile = "default"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::054704909064:role/OrganizationAccountAccessRole"
    session_name = "playground-organizationaccountaccessrole"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-085925f297f89fce1"
  instance_type = "t2.micro"
  tags = {
    Name = "Terraform Instance",
    Description = "Test provisioning instance with Terraform"
  }
}


