terraform {
    backend "remote" {
    hostname = "app.terraform.io"
    organization = "Nterone"

    workspaces {
      name = "awsexport-to-istlocal-stage1"
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
  default = "i-0c7b6ee0361b0dc2c"
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

variable "AWS_ACCESS_KEY_ID" {
  type = string
  description = "Key"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
  description = "Secret"
}

variable "AWS_DEFAULT_REGION" {
  type = string
  description = "Region for instance discovery"
  default = "us-west-2"
}

#data "template_file" "log_name" {
#  template = "${path.module}/output.log"
#}

#data "aws_s3_bucket_object" "log_name" {
#  bucket = "n1poc-bucket"
#  key    = "logs/output.log"
#}


#data "local_file" "create_s3export" {
#  value = create_s3export.stdout
#  depends_on = [create_s3export]
#}

module "create_s3export" {
  source  = "matti/resource/shell"
  version = "1.3.0"
  # insert the 4 required variables here
  environment = {
                    AWS_ACCESS_KEY_ID = var.AWS_ACCESS_KEY_ID
                    AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
                    AWS_DEFAULT_REGION=var.AWS_DEFAULT_REGION
                  }
  command = "aws ec2 create-instance-export-task --instance-id ${var.instanceid} --target-environment vmware --export-to-s3-task DiskImageFormat=vmdk,ContainerFormat=ova,S3Bucket=${var.s3bucket},S3Prefix=${var.s3folder}"             
}


    
#resource "null_resource" "create-s3export" {
#  provisioner "local-exec" {
#      command = "aws ec2 create-instance-export-task --instance-id ${var.instanceid} --target-environment vmware --export-to-s3-task DiskImageFormat=vmdk,ContainerFormat=ova,S3Bucket=${var.s3bucket},S3Prefix=${var.s3folder} > ${data.aws_s3_bucket_object.log_name.body}"           
#      environment = {
#                    AWS_ACCESS_KEY_ID = var.AWS_ACCESS_KEY_ID
#                    AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
#                  }
#                 
#  }
#}

locals {
  s3data = module.create_s3export.stdout  
  s3info = jsondecode("${local.s3data}")
  s3task = local.s3info.ExportTask.ExportTaskId
  s3out = local.s3info.ExportTask.ExportToS3Task.S3Key
  depends_on = [module.create_s3export]
}


#output "exports3_info" {
#  value = "${data.local_file.create_s3export.content}"
#}

output "exports3_url" {
  value = "https://${var.s3bucket}.s3.${var.AWS_DEFAULT_REGION}.amazonaws.com/${local.s3out}"
}

output "exports3_task" {
  value = "${local.s3task}"
}
