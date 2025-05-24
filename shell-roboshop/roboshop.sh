#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03d93947d06697ec0"
SUBNET_ID="subnet-01be324df23d176f9"
ZONE_ID="Z05550482K6DBOPR7GPPB"
DOMAIN_NAME="satyology.site"

INSTANCES=("MONGODB" "REDDIS" "MYSQL" "RABBITMQ" "CATALOGUE" "USER" "CART" "SHIPPING" "PAYMENT" "DISPATCH" "FRONTEND")

for INSTANCE in "${INSTANCES[@]}"; do
        echo "Launching instance $INSTANCE"

        INSTANCE_ID=$(aws ec2 run-instances \
                --image-id "$AMI_ID" \
                --instance-type t2.micro \
                --subnet-id "$SUBNET_ID" \
                --security-group-ids "$SG_ID" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
                --query "Instances[0].InstanceId" \
                --output text)

        echo "Instance ID: $INSTANCE_ID"

        # Wait for the instance to be in running state
        aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

        if [ "$INSTANCE" == "FRONTEND" ]; then
                IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                        --query "Reservations[0].Instances[0].PublicIpAddress" \
                        --output text)
                RECORD_NAME="$DOMAIN_NAME"
        else
                IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                        --query "Reservations[0].Instances[0].PrivateIpAddress" \
                        --output text)
                RECORD_NAME="$INSTANCE.$DOMAIN_NAME"
        fi

        echo "Updating Route53 Record: $RECORD_NAME -> $IP"

        aws route53 change-resource-record-sets \
                --hosted-zone-id "$ZONE_ID" \
                --change-batch "{
            \"Comment\": \"Creating or Updating a record set\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 60,
                    \"ResourceRecords\": [{
                        \"Value\": \"$IP\"
                    }]
                }
            }]
        }"
done
