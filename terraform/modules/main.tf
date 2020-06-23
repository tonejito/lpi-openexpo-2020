################################################################################
# https://www.terraform.io/docs/configuration/variables.html

variable "tags" {}
variable "aws_region" {}
variable "key_name" {}
variable "ssh_key_file" {}
variable "route53_zone_id" {}
variable "dns_domain" {}
variable "default_instance_type" {}
variable "root_volume_size" {}
variable "vpc_id" {}
variable "default_ami" {}
variable "default_subnet" {}
variable "ec2_instances" {
  type = list(map(string))
}

################################################################################
# https://www.terraform.io/docs/providers/aws/
provider "aws" {
  region  = var.aws_region
}

provider "random" {}
provider "null" {}
provider "template" {}

################################################################################
# https://www.terraform.io/docs/backends/types/s3.html
# The configuration for this backend will be filled in by Terragrunt

terraform {
  backend "s3" {}
}

################################################################################
# https://www.terraform.io/docs/providers/random/r/id.html

resource "random_id" "id" {
  byte_length = 8
  prefix      = ""
}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/security_group.html

resource "aws_security_group" "allow_all" {
  count       = length(var.ec2_instances)
  name        = "allow_all_traffic-${random_id.id.hex}-${count.index}"
  description = "Allow all traffic"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "allow_all_traffic-${random_id.id.hex}-${count.index}" }, var.tags)

  ingress {
    description = "pass in all"
    protocol          = "-1"
    from_port         = "0"
    to_port           = "0"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    description = "pass out all"
    protocol          = "-1"
    from_port         = "0"
    to_port           = "0"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/security_group_rule.html
# TODO: Create SG rules in array

// resource "aws_security_group_rule" "allow_all_ingress" {
//   security_group_id = aws_security_group.allow_all.id
//   description       = "pass in all"
//   type              = "ingress"
//   protocol          = "-1"
//   from_port         = "0"
//   to_port           = "0"
//   cidr_blocks       = ["0.0.0.0/0"]
//   ipv6_cidr_blocks  = ["::/0"]
// }
//
// resource "aws_security_group_rule" "allow_all_egress" {
//   security_group_id = aws_security_group.allow_all.id
//   description       = "pass out all"
//   type              = "egress"
//   protocol          = "-1"
//   from_port         = "0"
//   to_port           = "0"
//   cidr_blocks       = ["0.0.0.0/0"]
//   ipv6_cidr_blocks  = ["::/0"]
// }

################################################################################
# https://www.terraform.io/docs/providers/aws/r/key_pair.html
# $ mkdir -vp ~/.ssh/keys
# $ chmod 0700 ~/.ssh/keys
# $ ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/keys/aws-ciencias_rsa -C "andres.hernandez@ciencias.unam.mx"

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.key_name}-${random_id.id.hex}"
  tags       = var.tags
  public_key = file("${var.ssh_key_file}")
  # public_key = "ssh-rsa ... email@example.com"
}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/instance.html
# TODO: Add /64 ipv6_cidr_block to aws_subnet to use
# ipv6_address_count in aws_instance
#
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/installing-cloudwatch-agent-commandline.html
# TODO: Install CloudWatch Agent via ansible to get memory and OS metrics
#
# Turn off "disable_api_termination" before deleting the EC2 instance
# aws ec2 describe-instance-attribute --instance-id ${INSTANCE_ID} --attribute disableApiTermination
# aws ec2 modify-instance-attribute --instance-id ${INSTANCE_ID} --no-disable-api-termination

resource "aws_instance" "ec2_instance" {
  count                   = length(var.ec2_instances)
  ami                     = lookup(var.ec2_instances[count.index], "AMI", var.default_ami)
  instance_type           = lookup(var.ec2_instances[count.index], "InstanceType", var.default_instance_type)
  key_name                = aws_key_pair.ssh_key.key_name
  ebs_optimized           = "false"  # false for t2
  monitoring              = "false"
  subnet_id               = lookup(var.ec2_instances[count.index], "Subnet", var.default_subnet)
  disable_api_termination = "true"  # Prevent the instance from being deleted by accident
  vpc_security_group_ids  = [aws_security_group.allow_all[count.index].id]
  root_block_device {
    volume_size = var.root_volume_size
  }
  user_data   = "" # TODO: bootstrap from file
  tags        = merge({ "Name" = lookup(var.ec2_instances[count.index], "Name", "EC2-${random_id.id.hex}-${count.index}") }, var.tags)
  volume_tags = merge({ "Name" = lookup(var.ec2_instances[count.index], "Name", "EC2-${random_id.id.hex}-${count.index}") }, var.tags)
}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/eip.html

resource "aws_eip" "elastic_ip" {
  count    = length(var.ec2_instances)
  instance = aws_instance.ec2_instance[count.index].id
  vpc      = true
  tags     = merge({ "Name" = lookup(var.ec2_instances[count.index], "Name", "EC2-${random_id.id.hex}-${count.index}") }, var.tags)
}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/eip_association.html

resource "aws_eip_association" "elastic_ip_association" {
  count         = length(var.ec2_instances)
  instance_id   = aws_instance.ec2_instance[count.index].id
  allocation_id = aws_eip.elastic_ip[count.index].id
}

################################################################################
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# TODO: Add AAAA public and private records when IPv6 support is ebs_enabled
# on aws_subnet and aws_instance

resource "aws_route53_record" "public_record_a" {
  count   = length(var.ec2_instances)
  zone_id = var.route53_zone_id
  name    = "${lookup(var.ec2_instances[count.index], "Name", "ec2-${random_id.id.hex}-${count.index}") }.${var.dns_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.elastic_ip[count.index].public_ip]
}

resource "aws_route53_record" "private_record_a" {
  count   = length(var.ec2_instances)
  zone_id = var.route53_zone_id
  name    = "${lookup(var.ec2_instances[count.index], "Name", "ec2-${random_id.id.hex}-${count.index}") }.priv.${var.dns_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.elastic_ip[count.index].private_ip]
}

################################################################################
# https://www.terraform.io/docs/configuration/outputs.html

output "dns_records_a" {
  value = [
    aws_route53_record.public_record_a.*.name,
  ]
}
