
data "aws_availability_zones" "all" {}

# data "terraform_remote_state" "db" {
#   backend = "s3"
#   config = {
#     # Replace this with your bucket name!
#     bucket = "basher590-terraform-state"
#     key    = "global/s3/remotestate/stage/datastore/mysql/terraform.tfstate"
#     region = "eu-west-2"
#   }
# }

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "basher590-terraform-state"
    key            = "global/s3/remotestate/services/frontend/${var.cluster_name}/terraform.tfstate"
    region         = "eu-west-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_launch_configuration" "example" {
  image_id           = "ami-03084b454e06c336d"
  instance_type = var.instance_size
  security_groups = [aws_security_group.instance.id]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World." >> index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  min_size = var.asg_min
  max_size = var.asg_max
  availability_zones   = data.aws_availability_zones.all.names
  load_balancers    = [aws_elb.example.name]
  health_check_type = "ELB"
  
  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
  # tag {
  #   key                 = "Name"
  #   value               = "${var.cluster_name}"
  #   propagate_at_launch = true
  # }
}

resource "aws_elb" "example" {
  name               = "${var.cluster_name}-elb-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups    = [aws_security_group.elb.id]

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }


  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

