#Create our task for our service to use
resource "aws_ecs_task_definition" "website" {
  	container_definitions    = data.template_file.web_task_json.rendered
  	execution_role_arn       = aws_iam_role.ecs-task-role.arn
  	family                   = "website-container-${local.production_name}"
  	network_mode             = "awsvpc"
  	requires_compatibilities = ["EC2"]
  	task_role_arn            = aws_iam_role.ecs-task-role.arn
	lifecycle {
  	  ignore_changes = [ container_definitions, ]
  	}
} 

#Pull template data for our task and store it for use
data "template_file" "web_task_json" {
  	template = file("${path.module}/conf/web_task.json")
	
	#Change template variables 
  	vars = {
		region = local.region
		#Nginx variables
		name-nginx = "nginx-container-${local.production_name}"
    	image-nginx  = "${aws_ecr_repository.repo.repository_url}:website-v1"
		logname-nginx = aws_cloudwatch_log_group.log_group_nginx.name

  	}
}

#Create our task for our service to use
resource "aws_ecs_task_definition" "mongo" {
  	container_definitions    = data.template_file.mongo_task_json.rendered
  	execution_role_arn       = aws_iam_role.ecs-task-role.arn
  	family                   = "mongo-container-${local.production_name}"
  	network_mode             = "awsvpc"
  	requires_compatibilities = ["EC2"]
  	task_role_arn            = aws_iam_role.ecs-task-role.arn
	volume {
    	name = "mongo-storage"

    	efs_volume_configuration {
      		file_system_id          = aws_efs_file_system.mongo.id
      		root_directory          = "/"
			transit_encryption      = "ENABLED"
      		authorization_config {
        		access_point_id = aws_efs_access_point.mongo.id
				iam = "ENABLED"
			}
      	}
    }
	lifecycle {
  	  ignore_changes = [ volume, container_definitions,]
  	}
} 

#Pull template data for our task and store it for use
data "template_file" "mongo_task_json" {
  	template = file("${path.module}/conf/mongo_task.json")
	
	#Change template variables 
  	vars = {
		region = local.region

		#Mongo variables
		name-mongo = "mongo-container-${local.production_name}"
    	image-mongo  = "${aws_ecr_repository.repo.repository_url}:mongo-v1"
		logname-mongo = aws_cloudwatch_log_group.log_group_mongo.name
		mongo-admin = local.mongo_admin
		mongo-password = local.mongo_password
  	}
}

#Create our EFS file system for mongo
resource "aws_efs_file_system" "mongo" {
  	creation_token = "mongo-${local.production_name}"
  	tags = {
    	Name = "mongo-${local.production_name}"
  	}
}

resource "aws_efs_access_point" "mongo" {
  	file_system_id = aws_efs_file_system.mongo.id
}

#Mount it to our subnets
resource "aws_efs_mount_target" "mongo-sub-a" {
  	file_system_id = aws_efs_file_system.mongo.id
  	subnet_id      = aws_subnet.sub-a.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "mongo-sub-b" {
  	file_system_id = aws_efs_file_system.mongo.id
  	subnet_id      = aws_subnet.sub-b.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "mongo-sub-c" {
  	file_system_id = aws_efs_file_system.mongo.id
  	subnet_id      = aws_subnet.sub-c.id
	security_groups  = [aws_security_group.efs.id]
}

#Create our task for our service to use
resource "aws_ecs_task_definition" "postgres" {
  	container_definitions    = data.template_file.postgres_task_json.rendered
  	execution_role_arn       = aws_iam_role.ecs-task-role.arn
  	family                   = "postgres-container-${local.production_name}"
  	network_mode             = "awsvpc"
  	requires_compatibilities = ["EC2"]
  	task_role_arn            = aws_iam_role.ecs-task-role.arn
	volume {
    	name = "postgres-storage"

    	efs_volume_configuration {
      		file_system_id          = aws_efs_file_system.postgres.id
      		root_directory          = "/"
			transit_encryption      = "ENABLED"
      		authorization_config {
        		access_point_id = aws_efs_access_point.postgres.id
				iam = "ENABLED"
			}
      	}
    }
	lifecycle {
  	  ignore_changes = [ volume, container_definitions,]
  	}
} 

#Pull template data for our task and store it for use
data "template_file" "postgres_task_json" {
  	template = file("${path.module}/conf/postgres_task.json")
	
	#Change template variables 
  	vars = {
		region = local.region

		#postgres variables
		name-postgres = "postgres-container-${local.production_name}"
    	image-postgres  = "${aws_ecr_repository.repo.repository_url}:postgres-v1"
		logname-postgres = aws_cloudwatch_log_group.log_group_postgres.name
		postgres-admin = local.postgres_admin
		postgres-password = local.postgres_password
  	}
}

#Create our EFS file system for postgresql
resource "aws_efs_file_system" "postgres" {
  	creation_token = "postgres-${local.production_name}"
  	tags = {
    	Name = "postgres-${local.production_name}"
  	}
}

resource "aws_efs_access_point" "postgres" {
  	file_system_id = aws_efs_file_system.postgres.id
}

#Mount it to our subnets
resource "aws_efs_mount_target" "postgres-sub-a" {
  	file_system_id = aws_efs_file_system.postgres.id
  	subnet_id      = aws_subnet.sub-a.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "postgres-sub-b" {
  	file_system_id = aws_efs_file_system.postgres.id
  	subnet_id      = aws_subnet.sub-b.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "postgres-sub-c" {
  	file_system_id = aws_efs_file_system.postgres.id
  	subnet_id      = aws_subnet.sub-c.id
	security_groups  = [aws_security_group.efs.id]
}

#Create our nodejs task for our service to use
resource "aws_ecs_task_definition" "nodejs" {
  	container_definitions    = data.template_file.nodejs_task_json.rendered
  	execution_role_arn       = aws_iam_role.ecs-task-role.arn
  	family                   = "nodejs-container-${local.production_name}"
  	network_mode             = "awsvpc"
  	requires_compatibilities = ["EC2"]
  	task_role_arn            = aws_iam_role.ecs-task-role.arn
	volume {
    	name = "nodejs-storage"

    	efs_volume_configuration {
      		file_system_id          = aws_efs_file_system.nodejs.id
      		root_directory          = "/"
			transit_encryption      = "ENABLED"
      		authorization_config {
        		access_point_id = aws_efs_access_point.nodejs.id
				iam = "ENABLED"
			}
      	}
    }
	
	lifecycle {
  	  ignore_changes = [ volume, container_definitions,]
  	}
} 

#Pull template data for our task and store it for use
data "template_file" "nodejs_task_json" {
  	template = file("${path.module}/conf/nodejs_task.json")
	
	#Change template variables 
  	vars = {
		region = local.region

		#nodejs variables
		name-nodejs = "nodejs-container-${local.production_name}"
    	image-nodejs  = "${aws_ecr_repository.repo.repository_url}:nodejs-v1"
		logname-nodejs = aws_cloudwatch_log_group.log_group_nodejs.name
  	}
}

#Create our EFS file system for nodejs
resource "aws_efs_file_system" "nodejs" {
  	creation_token = "nodejs-${local.production_name}"
  	tags = {
    	Name = "nodejs-${local.production_name}"
  	}
}

resource "aws_efs_access_point" "nodejs" {
  	file_system_id = aws_efs_file_system.nodejs.id
}

#Mount it to our subnets
resource "aws_efs_mount_target" "nodejs-sub-a" {
  	file_system_id = aws_efs_file_system.nodejs.id
  	subnet_id      = aws_subnet.sub-a.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "nodejs-sub-b" {
  	file_system_id = aws_efs_file_system.nodejs.id
  	subnet_id      = aws_subnet.sub-b.id
	security_groups  = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "nodejs-sub-c" {
  	file_system_id = aws_efs_file_system.nodejs.id
  	subnet_id      = aws_subnet.sub-c.id
	security_groups  = [aws_security_group.efs.id]
}
