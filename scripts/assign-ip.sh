#!/bin/bash
aws configure set region us-west-2
# export AWS_DEFAULT_REGION="us-west-2"
export DNS="logicflux.tech"
export ZONE="${zone_id}"
export TTL="300"
export REGION="us-west-2"

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ALLOCATION_ID=$(aws ec2 describe-addresses --region $REGION --filters "Name=tag:Name,Values=asg-pool" | jq -r '.Addresses[] | "\(.InstanceId) \(.AllocationId)"' | grep null | awk '{print $2}' | xargs shuf -n1 -e)


if [ ! -z $ALLOCATION_ID ]; then
    # aws ec2 instance-status-ok --instance-ids $INSTANCE_ID && \
    aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID --allow-reassociation
    while [ $? -ne 0 ]; do
      aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID --allow-reassociation
      sleep 2
    done
fi

mkdir /ovpn-data
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efs_dns}:/ /ovpn-data
echo "${efs_dns}:/ /ovpn-data nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 " >> /etc/fstab
systemctl start docker
docker run -v /ovpn-data:/etc/openvpn -d -p 443:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn

sleep 120

PUBLIC_HOSTNAME=$(ec2metadata | grep 'public-hostname:' | cut -d ' ' -f 2 | head -n1 )
PUBLIC_IP=$(ec2metadata | grep 'public-ipv4:' | cut -d ' ' -f 2 | head -n1 )

DNS_CHECK=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE --query "ResourceRecordSets[?Name == '$PUBLIC_HOSTNAME.$DNS.']" | jq -r '.[].Name' | wc -l )

if [ $DNS_CHECK == 0 ]
  then
    cli53 rrcreate "$ZONE" "$PUBLIC_HOSTNAME $TTL A $PUBLIC_IP"

    RESOURCE_ID=$(aws route53 create-health-check \
      --caller-reference $PUBLIC_IP \
      --health-check-config=IPAddress=$PUBLIC_IP,Type=TCP,Port=443 | grep -i id | cut -d ":" -f2 | sed 's/"/ /g' | sed 's/,/ /g')

    aws route53 change-tags-for-resource --resource-type healthcheck --resource-id $RESOURCE_ID --add-tags Key=openvpn,Value=node-$PUBLIC_IP

    SNS_TOPIC=$( aws sns list-topics --region us-east-1 | jq -r '.Topics[]' | cut -d ':' -f2- | sed 's/"/ /g' | tr -d '{}' )

    aws cloudwatch put-metric-alarm \
        --alarm-name "vpn-node-alarm$PUBLIC_IP" \
        --alarm-description "route53 dns healthcheck alarm" \
        --metric-name "HealthCheckStatus" \
        --namespace "AWS/Route53" \
        --dimensions "Name=HealthCheckId,Value=$RESOURCE_ID" \
        --period 60 \
        --evaluation-periods 1 \
        --statistic "Minimum"\
        --threshold 1 \
        --comparison-operator "LessThanThreshold" \
        --alarm-actions $SNS_TOPIC --region us-east-1

  else
    echo "DNS recordset already exists!"

  fi
