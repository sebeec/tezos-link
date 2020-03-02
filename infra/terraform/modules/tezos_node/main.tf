data "aws_ami" "rhel" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-8.1.0_HVM-20191029-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"] # RedHat
}

resource "aws_instance" "tz_node" {
  ami           = data.aws_ami.rhel.id
  instance_type = var.INSTANCE_TYPE
  subnet_id     = tolist(data.aws_subnet_ids.tzlink.ids)[0]

  key_name = var.KEY_PAIR_NAME

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.tzlink_backup_access.name

  vpc_security_group_ids = [ aws_security_group.tezos_node.id ]

  user_data=templatefile("${path.module}/user_data.tpl", {})

  tags = {
    Name        = format("tzlink-%s-test", var.ENV)
    Project     = var.PROJECT_NAME
    Environment = var.ENV
    BuildWith   = var.BUILD_WITH
  }
}

resource "aws_iam_instance_profile" "tzlink_backup_access" {
  name = "tzlink_backup_access"
  role = data.aws_iam_role.tzlink_backup_access.name
}

data "aws_iam_role" "tzlink_backup_access" {
  name = "tzlink_backup_access"
}