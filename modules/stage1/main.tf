terraform {
    backend "remote" {
    hostname = "app.terraform.io"
    organization = "N1-POC"

    workspaces {
      name = "awsexport-to-istlocal"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

variable "instanceid" {
  type = string
  description = "Instance ID to export"
  default = "i-051bcd2e285390149"
}

variable "s3bucket" {
  type = string
  description = "S3 Bucket Name to export OVA file"
  default = "n1poc-bucket"
}

variable "s3folder" {
  type = string
  description = "Folder to export the OVA to. Must exist"
  default = "vms/"
}



data "template_file" "log_name" {
  template = "${path.module}/output.log"
}

data "local_file" "create_s3export" {
  filename = "${data.template_file.log_name.rendered}"
  depends_on = [null_resource.create-s3export]
}


resource "null_resource" "create-s3export" {
  provisioner "local-exec" {
                 command = "aws ec2 create-instance-export-task --instance-id ${var.instanceid} --target-environment vmware --export-to-s3-task DiskImageFormat=vmdk,ContainerFormat=ova,S3Bucket=${var.s3bucket},S3Prefix=${var.s3folder} > ${data.template_file.log_name.rendered}"
  }
}

locals {
  s3info = jsondecode("${data.local_file.create_s3export.content}")
  s3task = [for Task in local.s3info.ExportTasks : Task.ExportTaskId]
  s3out = [for Task in local.s3info.ExportTasks : Task.ExportToS3Task.S3Key]
  depends_on = [null_resource.create-s3export]
}


output "exports3_info" {
  value = "${data.local_file.create_s3export.content}"
}

output "exports3_url" {
  value = "${local.s3out}"
}

output "exports3_task" {
  value = "${local.s3task}"
}
