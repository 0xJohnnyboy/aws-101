#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [--cred <path>] [-C <path>] [--region <region>]"
    echo "  --cred, -C : Path to the AWS credentials file"
    echo "  --region   : AWS region (default: us-east-1)"
}

# Process command-line arguments
CRED_FILE=""
REGION="us-east-1"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --cred|-C) CRED_FILE="$2"; shift ;;
        --region) REGION="$2"; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Check if credentials file is specified and exists
if [ -z "$CRED_FILE" ] || [ ! -f "$CRED_FILE" ]; then
    echo "Error: AWS credentials file not specified or not found."
    show_help
    exit 1
fi

# Set AWS credentials
export AWS_SHARED_CREDENTIALS_FILE="$CRED_FILE"
export AWS_DEFAULT_REGION="$REGION"

# Function to delete AWS resources
delete_aws_resources() {
    echo "Deleting AWS resources..."

    # Delete EC2 instances
    instances=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text)
    if [ ! -z "$instances" ]; then
        echo "Terminating EC2 instances: $instances"
        aws ec2 terminate-instances --instance-ids $instances
        echo "Waiting for instances to terminate..."
        aws ec2 wait instance-terminated --instance-ids $instances
    else
        echo "No EC2 instances to terminate."
    fi

    # Delete ELBs
    elbs=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text)
    for elb in $elbs; do
        echo "Deleting ELB: $elb"
        aws elb delete-load-balancer --load-balancer-name $elb
    done

    # Delete VPCs and associated resources
    vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text)
    for vpc in $vpcs; do
        echo "Deleting resources for VPC: $vpc"
        
        # Delete NAT Gateways
        nat_gateways=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" --query 'NatGateways[].NatGatewayId' --output text)
        for nat in $nat_gateways; do
            echo "Deleting NAT Gateway: $nat"
            aws ec2 delete-nat-gateway --nat-gateway-id $nat
        done

        # Delete Elastic IPs
        eips=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text)
        for eip in $eips; do
            echo "Releasing Elastic IP: $eip"
            aws ec2 release-address --allocation-id $eip
        done

        # Delete route tables
        route_tables=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[].RouteTableId' --output text)
        for rt in $route_tables; do
            # Dissociate route table associations
            route_table_associations=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[].Associations[].RouteTableAssociationId' --output text)
            for assoc in $route_table_associations; do
                echo "Dissociating Route Table Association: $assoc"
                aws ec2 disassociate-route-table --association-id $assoc
            done

            # Delete specific routes in the route table (e.g., Internet Gateway, NAT Gateway routes)
            routes=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[].Routes[?GatewayId!=null].DestinationCidrBlock' --output text)
            for route in $routes; do
                echo "Deleting route: $route from Route Table: $rt"
                aws ec2 delete-route --route-table-id $rt --destination-cidr-block $route
            done

            # Now delete the route table
            echo "Deleting Route Table: $rt"
            aws ec2 delete-route-table --route-table-id $rt

        done

        # Delete network interfaces
        network_interfaces=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text)
        for ni in $network_interfaces; do
            echo "Deleting Network Interface: $ni"
            aws ec2 delete-network-interface --network-interface-id $ni
        done

        # Delete VPC endpoints
        vpc_endpoints=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc" --query 'VpcEndpoints[].VpcEndpointId' --output text)
        for vpc_endpoint in $vpc_endpoints; do
            echo "Deleting VPC Endpoint: $vpc_endpoint"
            aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpc_endpoint
        done


        # Delete subnets
        subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text)
        for subnet in $subnets; do
            echo "Deleting subnet: $subnet"
            aws ec2 delete-subnet --subnet-id $subnet
        done

        # Delete Internet Gateways
        igws=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text)
        for igw in $igws; do
            echo "Detaching and deleting Internet Gateway: $igw"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
            aws ec2 delete-internet-gateway --internet-gateway-id $igw
        done

        # Delete security groups (except default)
        sgs=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
        for sg in $sgs; do
            echo "Deleting Security Group: $sg"
            aws ec2 delete-security-group --group-id $sg
        done

        # Delete VPC
        echo "Deleting VPC: $vpc"
        aws ec2 delete-vpc --vpc-id $vpc
    done

    echo "AWS resource deletion completed."
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it and try again."
    exit 1
fi

# Main execution
delete_aws_resources

echo "Cleanup finished."
