#Create our website service
resource "aws_ecs_service" "website" {
    name            = "website-${local.production_name}"
    cluster         = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.website.arn
    launch_type     = "EC2" 
    desired_count   = 1
    depends_on      = [aws_iam_role.ecs-instance-role,aws_lb_listener.lb_listener_80,aws_lb_listener.lb_listener_443]

    ordered_placement_strategy {
        type  = "binpack"
        field = "cpu"
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_target_80.arn
        container_name   = "nginx-container-${local.production_name}"
        container_port   = 80
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_target_443.arn
        container_name   = "nginx-container-${local.production_name}"
        container_port   = 443
    }

    network_configuration {
        security_groups       = [aws_security_group.webservers.id]
        subnets               = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
        assign_public_ip      = "false"
    }

    placement_constraints {
        type       = "memberOf"
        expression = "attribute:ecs.availability-zone in [${local.region}a, ${local.region}b, ${local.region}c]"
    }
}

#Create what our auto scaling targets are
resource "aws_appautoscaling_target" "ecs_target" {
    max_capacity       = 20
    min_capacity       = 1
    resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.website.name}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
}

#Create what our policy trigger is to create a new task
resource "aws_appautoscaling_policy" "ecs_target" {
    name               = "cpu-auto-scaling-${local.production_name}"
    service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
    scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
    resource_id        = aws_appautoscaling_target.ecs_target.resource_id
    policy_type        = "TargetTrackingScaling"

    #Create a new task when CPU ussage for container is over 75%
    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }

        target_value       = 75
        scale_in_cooldown  = 300
        scale_out_cooldown = 300
    }
}

#Create our website service
resource "aws_ecs_service" "mongo" {
    name            = "mongo-${local.production_name}"
    cluster         = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.mongo.arn
    launch_type     = "EC2" 
    desired_count   = 1
    depends_on      = [aws_lb_listener.lb_listener_27017]

    ordered_placement_strategy {
        type  = "binpack"
        field = "cpu"
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_target_27017.arn
        container_name   = "mongo-container-${local.production_name}"
        container_port   = 27017
    }

    network_configuration {
        security_groups       = [aws_security_group.mongo.id]
        subnets               = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
        assign_public_ip      = "false"
    }

    placement_constraints {
        type       = "memberOf"
        expression = "attribute:ecs.availability-zone in [${local.region}a, ${local.region}b, ${local.region}c]"
    }
}

#Create our postgres service
resource "aws_ecs_service" "postgres" {
    name            = "postgres-${local.production_name}"
    cluster         = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.postgres.arn
    launch_type     = "EC2" 
    desired_count   = 1
    depends_on      = [aws_lb_listener.lb_listener_5432]

    ordered_placement_strategy {
        type  = "binpack"
        field = "cpu"
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_target_5432.arn
        container_name   = "postgres-container-${local.production_name}"
        container_port   = 5432
    }

    network_configuration {
        security_groups       = [aws_security_group.postgres.id]
        subnets               = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
        assign_public_ip      = "false"
    }

    placement_constraints {
        type       = "memberOf"
        expression = "attribute:ecs.availability-zone in [${local.region}a, ${local.region}b, ${local.region}c]"
    }
}

#Create our nodejs server
resource "aws_ecs_service" "nodejs" {
    name            = "nodejs-${local.production_name}"
    cluster         = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.nodejs.arn
    launch_type     = "EC2" 
    desired_count   = 1
    depends_on      = [aws_lb_listener.lb_listener_8080]

    ordered_placement_strategy {
        type  = "binpack"
        field = "cpu"
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_target_8080.arn
        container_name   = "nodejs-container-${local.production_name}"
        container_port   = 8080
    }

    network_configuration {
        security_groups       = [aws_security_group.nodejs.id]
        subnets               = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
        assign_public_ip      = "false"
    }

    placement_constraints {
        type       = "memberOf"
        expression = "attribute:ecs.availability-zone in [${local.region}a, ${local.region}b, ${local.region}c]"
    }
}