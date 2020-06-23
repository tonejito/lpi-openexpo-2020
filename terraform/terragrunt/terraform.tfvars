# https://linuxlifecycle.com/
# https://ec2instances.info/
# https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
# https://cloud-images.ubuntu.com/locator/ec2/
# https://wiki.centos.org/Cloud/AWS#Official_CentOS_Linux_:_Public_Images
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;ownerAlias=amazon;description=Amazon%20Linux%202%20AMI;sort=desc:name

tags = {
  Terraform = "True"
}

aws_region = "us-east-1" # Virginia
route53_zone_id = "Z39MY7791RU9Z"
dns_domain = "demo.tonejito.cf"
key_name = "openexpo-lpi_rsa"
ssh_key_file = "~/.ssh/keys/openexpo-lpi_rsa.pub"

default_instance_type = "t2.nano"
root_volume_size = "10"
vpc_id = "vpc-00159005c0ebb60b2"  # us-east-1
default_ami = "ami-0c30fc09f75b189a9" # amzn2-ami-minimal-hvm-2.0.20200520.1-x86_64-ebs
default_subnet = "subnet-09765ea8a8cfec8da"  # us-east-1a (use1-az4)

ec2_instances = [
  {
    # We can specify a custom instance type or inherit default if not defined
    "InstanceType" = "t2.nano",
    "Name" = "debian",  # hostname
    "User" = "admin",  # default user
    "AMI" = "ami-0f31df35880686b3f",  # Debian 10 (us-east-1)
    "Subnet" = "subnet-0d3f11df5d5ede32d",  # us-east-1b (use1-az6)
  },
  {
    "Name" = "ubuntu",  # hostname
    "User" = "ubuntu",  # default user
    "AMI" = "ami-02ae530dacc099fc9",  # Ubuntu 20.04 (us-east-1)
    "Subnet" = "subnet-0fd7ee541d75e5e6f",  # us-east-1c (use1-az1)
  },
  {
    "Name" = "centos",  # hostname
    "User" = "centos",  # default user
    "AMI" = "ami-0affd4508a5d2481b",  # CentOS 7 (us-east-1)
    "Subnet" = "subnet-0aa39bb21a5c7046b",  # us-east-1d (use1-az2)
  },
  {
    "Name" = "amazon",  # hostname
    "User" = "ec2-user",  # default user
    "AMI" = "ami-09d95fab7fff3776c",  # amzn2-ami-hvm-2.0.20200520.1-x86_64-gp2
    "Subnet" = "subnet-0426dbbda3db3bf19",  # us-east-1e (use1-az3)
  },
]
