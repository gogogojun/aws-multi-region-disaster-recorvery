terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "artifact_bucket" { type = string }
variable "artifact_prefix" { type = string }
variable "systemd_service" { type = string }

resource "aws_ssm_document" "deploy_jar" {
  name            = "${var.project}-DeployJar"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Download JAR from S3 and restart systemd",
    parameters = {
      S3Uri       = { type = "String", default = "s3://${var.artifact_bucket}/${var.artifact_prefix}app.jar" },
      ServiceName = { type = "String", default = var.systemd_service }
    },
    mainSteps = [{
      action = "aws:runShellScript",
      name   = "Deploy",
      inputs = {
        timeoutSeconds = 600,
        runCommand = [
          "set -e",
          "mkdir -p /opt/app",
          "aws s3 cp {{ S3Uri }} /opt/app/app.jar",
          "systemctl stop {{ ServiceName }} || true",
          "sleep 1",
          "systemctl start {{ ServiceName }}",
          "systemctl is-active {{ ServiceName }}"
        ]
      }
    }]
  })
}

output "document_name" { value = aws_ssm_document.deploy_jar.name }

