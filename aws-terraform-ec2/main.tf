# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnet (first available)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get latest Amazon Linux 2 AMI
# data "aws_ami" "default-ami" {
#   most_recent = true

#   owners = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# Create Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"] # ⚠️ open to all (for learning)
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Key Pair (uses your local public key)
resource "aws_key_pair" "my_key" {
  key_name   = "DevOps-Key"
  public_key = file("~/.ssh/DevOps-Key.pub")
}

# Create EC2 instance
resource "aws_instance" "ec2" {
#   ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  ami                    = "ami-053b0d53c279acc90" #Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.my_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "Terraform-EC2"
  }
}