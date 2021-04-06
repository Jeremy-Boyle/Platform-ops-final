#!/bin/bash

# Update all packages
sudo yum update -y

#Adding cluster name in ecs config
sudo runuser -l root -c 'echo ECS_CLUSTER=Website-Cluster-${name} >> /etc/ecs/ecs.config'
cat /etc/ecs/ecs.config | grep "ECS_CLUSTER"

