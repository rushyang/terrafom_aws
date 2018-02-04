# terrafom_aws
### This is an initial attempt at Terraform with AWS Provider, which does following tasks:
1. Create 2 EC2 instances using an autoscaling group. EC2 instances should have S3 Full Access Instance Role assigned.
2. Create a private bucket (Bucket name is given at the time of terraform apply - either using command line variable or via user-interaction)

### How to Execute:
1. Make sure both files are in same directory and there is no other \*.tf file, otherwise terraform apply will include that as well.
2. Execute `terraform init` to initialize current directory and download mentioned binaries of providers and templates in .terraform directory inside a current working directory
3. Execute `terraform apply –var 'aws_access_key_id=<your access key>' –var 'aws_secret_access_key=<your secret access key>' -var 'bucket_name=<a globally unique name>'` command with relevant AWS keys and Globally unique bucket name.

## Explanation on Code
### AWS Architecture/Interactions through Terraform file:site.tf (Explained according to architectural sequence)
1. IAM Role Creation with STS Assume Role through resource: aws_iam_role
2. Creation of "IN-LINE" IAM Policy through JSON format using "aws_iam_role_policy" and attach it to IAM
3. Creation of "Instance Role" using "aws_iam_instance_profile" and assigning previously created iam_role
4. Private S3 Bucket creation with user-entered (during terraform apply) unique global bucketname using AWS provider's resource: aws_s3_bucket
5. Using resource: "template_file", rendering a template file:UpdateAndMetadata.tpl to be used as a BootStrap script of EC2 instance's first instantiation.
6. Creation of ELB with listener and health checks using resource: aws_elb
7. Deciding AMI for free-tier - T2.Micro Instance type and create Launch Configuration using: aws_launch_configuration
8. Creation of autoscaling group and assign previously created Launch_Configuration, ELB with desired:2, and max: 3 instances

That's it!

Key Points:
1. key_name option in asw_launch_configuration is commented as it can never be same for two AWS users
2. Using vars option of template_file, it is essential to populate ${newlycreatedbucket} variable within file:UpdateAndMetadata.tpl to be able to copy file into newly created S3 bucket. This variable passing dynamically is essential.
3. AutoScaling Group instance should have instance role assigned to be able to upload file into newly created S3 bucket
4. It is wise to chose multiple AZs if max_size of autoscaling group is given more than 1.


### -Rushyang Darji
### rushyang01@gmail.com 
