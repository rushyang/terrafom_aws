# terrafom_aws
Initial attempt at Terraform with AWS provider
### This is an initial attempt at Terraform with AWS Provider, which does following tasks:
1. Create 2 EC2 instances using an autoscaling group. EC2 instances should have S3 Full Access Instance Role assigned.
2. Create a private bucket (Bucket name is given at the time of terraform apply - either using command line variable or via user-interaction)

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

### -Rushyang Darji
### rushyang01@gmail.com 
