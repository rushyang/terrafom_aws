# Variable block to be taken as an input 
# If no access key id and secret access ky provided, terraform will look for AWS keys in ~/.aws/credentials 
variable "aws_access_key_id" {} 
variable "aws_secret_access_key" {} 
variable "bucket_name" {}

# Defining provider as AWS for terraform init
provider "aws" {
	region	= "ap-southeast-2"
	profile = "telstrademo"
	access_key = "${var.aws_access_key_id}"
	secret_key = "${var.aws_secret_access_key}"
}

# Create S3 Bucket with Name provided in the variable: bucket_name
resource "aws_s3_bucket" "bucket" {
        bucket          = "${var.bucket_name}"
        acl             = "private"
        region          = "ap-southeast-2"

        tags {
                Name            = "S3 Bucket Telstra Demo"
                Environment     = "Demo"
        }
}

# Creating a ELB which would be assigned during creation of autoscaling_group 
resource "aws_elb" "web-elb" {
  name = "telstra-demo-elb"

  # The same availability zone as our instances
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags {
	Name	= "telstra-demo-elb"	
  }
}

# Create an autoscaling group
resource "aws_autoscaling_group" "telstra-autoscaling-group" {
	availability_zones		= ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
	name				= "telstra-autoscaling-group"
	max_size			= 3
	min_size			= 2
	health_check_grace_period	= 300
	health_check_type		= "ELB"
	desired_capacity		= 2
	force_delete			= true
	launch_configuration		= "${aws_launch_configuration.telstra-launch-config.name}"
	load_balancers			= ["${aws_elb.web-elb.name}"]
	# Essential because once instances under LC is created they cannot be altered. 
	lifecycle {
	 create_before_destroy		= true
	}
	#initial_lifecycle_hook	{
	#	name			= "foobar"
	#	default_result		= "CONTINUE"
	#	heartbeat_timeout	= 2000
	#	lifecycle_transition	= "autoscaling:EC2_INSTANCE_LAUNCHING"
	#	role_arn		= "arn:aws:iam:::role/TelstraDemoS3FullAccessRole"
	#}
	
	tag {
   		key                 = "Name"
		value               = "telstra-autoscaling-group"
		propagate_at_launch = "true"
  	}
}

# Create an initial LC to be attached with an auto scaling group
resource "aws_launch_configuration" "telstra-launch-config" {
	name			= "telstra-launch-config"
	image_id		= "ami-942dd1f6"
	instance_type 		= "t2.micro"
	# Assigning newly created security group
	security_groups		= ["${aws_security_group.telstra-demo-securitygroup.name}"]
	# Attaching S3Full access IAM instance profile with this LC
	iam_instance_profile	= "${aws_iam_instance_profile.demo-profile.name}" 
	# key_name		= "T2MicroSydney"
	user_data		= "${template_file.user_data.rendered}"
}

# Declaring IAM instance profile out of existing IAM role
resource "aws_iam_instance_profile" "demo-profile" {
        name            = "s3-full-access-to-ec2"
        role            = "${aws_iam_role.demo-role.name}"
}

# Create a new IAM role
resource "aws_iam_role" "demo-role" {
        name            = "TelstraDemoS3FullAccessRole"
        path            = "/"

        assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Creating IAM Role policy and attaching it with existing IAM role
resource "aws_iam_role_policy" "s3_demo_full_access_policy" {
        name            = "s3_demo_full_access_policy"
        role            = "${aws_iam_role.demo-role.id}"
        policy          = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

# Create a security group with ingress 22 and 80, egress * to attach with LC
resource "aws_security_group" "telstra-demo-securitygroup" {
	name		= "telstra-demo-securitygroup"
	description	= "Security group with 22 80 access"
	
	# SSH from anywhere
	ingress {
		from_port	= 22
		to_port		= 22
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}

	# HTTP from anywhere
	ingress {
		from_port	= 80
		to_port 	= 80
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	# outbound internet access
	egress {
		from_port	= 0
		to_port		= 0
		protocol	= "-1"
		cidr_blocks	= ["0.0.0.0/0"]
	}
}

# Calling a template file: UpdateAndMetadata.tpl (which is provided along with this site.tf)
# newlycreatedbucket variable inside this template file will be evaluated with entered bucket_name
# so that EC2 instance can dynamically get value and copy metadata file into newly created bucket

resource "template_file" "user_data" {
  template = "${file("UpdateAndMetadata.tpl")}"
  vars {
    newlycreatedbucket="${var.bucket_name}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
