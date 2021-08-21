# awsexport-to-ikslocal
Export EC2 Instance to S3 Bucket for Intersight Consumption using AWS CLI-TerraformCloud-Terraform OSS


If there was an easier way to do this...

This tf plans takes us on a two stage setup:

1- Use AWS CLI on a remote terraform linux VM based instance to export an EC2 VM. 
2- Import the VM and deploy it with Intersight on a vSphere environment
