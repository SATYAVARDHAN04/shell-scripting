#! /bin/bash

# TO RUN ROBOSHOP.SH NO NEED FOR ROOT ACCESS
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03d93947d06697ec0"
SUBNET_ID="subnet-01be324df23d176f9"
ZONE_ID="Z05550482K6DBOPR7GPPB"
DOMAIN_NAME="satyology.site"

INSTANCES=("mongodb" "mysql" "redis" "rabbitmq" "cart" "user" "dispatch" "payment" "shipping" "catalogue" "frontend")

#for instance in "${INSTANCES[@]}"; do
for instance in $@; do
    echo "Creating instance: $instance"
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t2.micro \
        --subnet-id $SUBNET_ID \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "Waiting for instance $INSTANCE_ID to initialize..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    if [ "$instance" == "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    fi

    echo "Setting DNS record for $RECORD_NAME -> $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch "{
        \"Comment\": \"Updating DNS for $instance\",
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 60,
                \"ResourceRecords\": [{ \"Value\": \"$IP\" }]
            }
        }]
    }"
done
