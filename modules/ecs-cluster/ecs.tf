#
# ECS ami
#
data "aws_ami" "ecs" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["591542846629"] # AWS
}

#
# ECS cluster
#
resource "aws_ecs_cluster" "cluster" {
  name = "${var.CLUSTER_NAME}"
}

#
# launchconfig
#
resource "aws_launch_configuration" "cluster" {
  name_prefix          = "ecs-${var.CLUSTER_NAME}-launchconfig"
  image_id             = "${data.aws_ami.ecs.id}"
  instance_type        = "${var.INSTANCE_TYPE}"
  key_name             = "${var.SSH_KEY_NAME}"
  iam_instance_profile = "${aws_iam_instance_profile.cluster-ec2-role.id}"
  security_groups      = ["${aws_security_group.cluster.id}"]

  user_data = templatefile("${path.module}/templates/ecs_init.tpl", {
    CLUSTER_NAME = var.CLUSTER_NAME
  })

  lifecycle {
    create_before_destroy = true
  }
}

#
# autoscaling
#
resource "aws_autoscaling_group" "cluster" {
  name                 = "ecs-${var.CLUSTER_NAME}-autoscaling"
  vpc_zone_identifier  = var.VPC_SUBNETS
  launch_configuration = aws_launch_configuration.cluster.name
  termination_policies = var.ECS_TERMINATION_POLICIES
  min_size             = var.ECS_MINSIZE
  max_size             = var.ECS_MAXSIZE
  desired_capacity     = var.ECS_DESIRED_CAPACITY
  tag {
    key                 = "Name"
    value               = "${var.CLUSTER_NAME}-ecs"
    propagate_at_launch = true
  }
}
