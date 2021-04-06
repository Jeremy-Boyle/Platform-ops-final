#Create our policys and roles to use
#Used in our EC2 instance that way it has
#Permission to talk to our ECS services
resource "aws_iam_role" "ecs-instance-role" {
    name = "ecs-instance-role-${local.production_name}"
    path = "/"
    assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json
}

#Create our data for our ecs-instance-role to use 
data "aws_iam_policy_document" "ecs-instance-policy" {
        statement {
            actions = ["sts:AssumeRole"]
            principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

#Attach our policy to our role
resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
    role = aws_iam_role.ecs-instance-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
    name = "ecs-instance-profile-${local.production_name}"
    path = "/"
    role = aws_iam_role.ecs-instance-role.id
    
    provisioner "local-exec" {
        command = "sleep 60"
    }
}

resource "aws_iam_role" "ecs-service-role" {
    name = "ecs-service-role-${local.production_name}"
    path = "/"
    assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
    role = aws_iam_role.ecs-service-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
    statement {
            actions = ["sts:AssumeRole"]
            principals {
            type = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

#Create a role our task to use
resource "aws_iam_role" "ecs-task-role" {
    name = "ecs-task-role-${local.production_name}"
    path = "/"
    assume_role_policy = data.aws_iam_policy_document.ecs-task-policy.json
}

#Create our data for our ecs-task-role to use 
data "aws_iam_policy_document" "ecs-task-policy" {
        statement {
            actions = ["sts:AssumeRole"]
            principals {
            type = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

#Attach our policy to our role
resource "aws_iam_role_policy_attachment" "ecs-instance-task-attachment" {
    role = aws_iam_role.ecs-task-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs-task-profile" {
    name = "ecs-task-profile-${local.production_name}"
    path = "/"
    role = aws_iam_role.ecs-task-role.id
    
    provisioner "local-exec" {
        command = "sleep 60"
    }
}