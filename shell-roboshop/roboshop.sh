#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03d93947d06697ec0"
SUBNET_ID="subnet-01be324df23d176f9"
INSTANCES=("MONGODB" "REDIS" "MYSQL" "RABBITMQ" "USER" "CART" "DISPATCH" "CATALOGUE" "SHIPPING" "PAYMENT" "FRONTEND")

ZONE_ID="Z05550482K6DBOPR7GPPB"
DOMAIN_NAME="satyology.site"

for instance in "${INSTANCES[@]}"; do
        echo "Launching instance: $instance"
        INSTANCE_ID=$(aws ec2 run-instances \
                --image-id $AMI_ID \
                --instance-type t3.micro \
                --subnet-id $SUBNET_ID \
                --security-group-ids $SG_ID \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
                --query "Instances[0].InstanceId" \
                --output text)

        echo "Instance ID: $INSTANCE_ID"

        echo "Waiting for instance to initialize..."
        sleep 10

        if [ "$instance" != "FRONTEND" ]; then
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                        --query "Reservations[0].Instances[0].PrivateIpAddress" \
                        --output text)
                RECORD_NAME="$instance.$DOMAIN_NAME"
        else
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                        --query "Reservations[0].Instances[0].PublicIpAddress" \
                        --output text)
                RECORD_NAME="$DOMAIN_NAME"
        fi

        echo "$instance IP address: $IP"

        aws route53 change-resource-record-sets \
                --hosted-zone-id $ZONE_ID \
                --change-batch '{
            "Comment": "Creating or Updating a record set"
            ,"Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'"$RECORD_NAME"'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{
                        "Value": "'"$IP"'"
                    }]
                }
            }]
        }'
done
