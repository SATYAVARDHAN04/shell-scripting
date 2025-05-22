#! /bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03d93947d06697ec0"
SUBNET_ID="subnet-01be324df23d176f9"
INSTANCES = ("MONGODB" "REDIS" "MYSQL" "RABBITMQ" "USER" "CART" "DISPATCH" "CATALOGUE" "SHIPPING" "PAYMENT" "FRONTEND")

ZONE_ID="Z05550482K6DBOPR7GPPB"
DOMAIN_NAME="satyology.site"

for instance in ${INSTANCES[@]}
do
        aws ec2 run-instances \
        --image-id ami-09c813fb71547fc4f \
        --instance-type t2.micro \
        --subnet-id subnet-01be324df23d176f9 \
        --security-group-ids sg-03d93947d06697ec0 \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=test}]"
done







# aws ec2 describe-instances \
#   --instance-ids i-05c20cd0dc885ccbd \
#   --query "Reservations[0].Instances[0].[PublicIpAddress, PrivateIpAddress]" \
#   --output text





