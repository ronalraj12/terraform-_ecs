
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.48.0"
    }
  }
}

provider "aws" {
    region     = "eu-west-2"
    access_key = "AKIATNS7C4QCCI5E5WNP"
    secret_key = "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"
}


resource "aws_ecr_repository" "my_first_ecr_repo" {
  name = "my-first-ecr-repo" 
  tags = {
    Name        = "latest-ecr"
  }
}

resource "aws_ecs_cluster" "my_cluster" {

  name = "my-cluster" 
}

resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "${aws_ecr_repository.my_first_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION
  requires_compatibilities = ["EC2"] 
  network_mode             = "awsvpc"    
  memory                   = 512         
  cpu                      = 256         
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_security_group_rule" "default" {
  type              = "ingress"
  from_port         = 0
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-06b7cd7a3f4949f86"
}
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_ecs_service" "my_first_services" {
    name            = "my-first-services"                            
    cluster         = "${aws_ecs_cluster.my_cluster.id}"            
    task_definition = "${aws_ecs_task_definition.my_first_task.arn}" 
    launch_type     = "EC2"
    scheduling_strategy  = "REPLICA"
    desired_count   = 1 
  
    network_configuration {
      subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
      assign_public_ip = false 
    }
  }
  

resource "aws_default_vpc" "default" {
}



resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-west-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-west-2b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "eu-west-2c"
}

