#!/bin/bash
yum update -y
yum install httpd -y
service httpd start 
chkconfig httpd on
for i in `curl http://169.254.169.254/latest/meta-data/`; do echo 'Data: ' $'\n\n''Data: ' $i; curl http://169.254.169.254/latest/meta-data/$i; done >> '/tmp/data-'`hostname`'.html'
aws s3 cp '/tmp/data-'`hostname`'.html' s3://${newlycreatedbucket}
