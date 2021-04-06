## Creating Launch Configuration
resource "aws_launch_configuration" "ec2_scale_temp" {
	name                   = "ec2_scale_temp-${local.production_name}"

	#Pull data for latest ami
	image_id               = data.aws_ami.ecs.id
	iam_instance_profile   = aws_iam_instance_profile.ecs-instance-profile.name
	instance_type          = "t3.small"
	security_groups        = [aws_security_group.webservers.id]

	#SSH Key
	key_name               = aws_key_pair.generated_key.key_name

	#Pull data and run as a script during boot
	user_data              = data.template_file.user_data.rendered

	lifecycle {
		create_before_destroy = true
	}
}

#Pull file data and save it as a template
data "template_file" "user_data" {
  template = file("${path.module}/conf/user_data.tpl")
    vars = {
		name = local.production_name
  	}

}

# Creating AutoScaling Group
resource "aws_autoscaling_group" "ec2_scale" {
	name                      = "ec2_scale-${local.production_name}"
	launch_configuration      = aws_launch_configuration.ec2_scale_temp.id
	vpc_zone_identifier       = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
	desired_capacity          = 1
	min_size                  = 1
	max_size                  = 10
	default_cooldown          = 30
	health_check_grace_period = 30

	tag {
		key = "Name"
		value = "Webserver-Worker-${local.production_name}"
		propagate_at_launch = true
	}
	lifecycle {
  	  ignore_changes = [desired_capacity]
  	}
}

#Create and attach the policy to our scale group
resource "aws_autoscaling_policy" "ecs_cluster_scale_policy" {
  	name = "ecs_cluster_scale_policy-${local.production_name}"
  	policy_type = "TargetTrackingScaling"
  	adjustment_type = "ChangeInCapacity"
	
  	lifecycle {
  	  ignore_changes = [adjustment_type]
  	}

  	autoscaling_group_name = aws_autoscaling_group.ec2_scale.name

	#Monitor for memory restriction, once a task is using 70% of 
	#resource memory we'll create a new one to stay under 70%
  	target_tracking_configuration {
    	customized_metric_specification {
      		metric_dimension {
        		name = "ClusterName"
        		value = aws_ecs_cluster.cluster.name
      		}
      		metric_name = "MemoryReservation"
      		namespace = "AWS/ECS"
      		statistic = "Average"
    	}
    	target_value = 70.0
  	}
}