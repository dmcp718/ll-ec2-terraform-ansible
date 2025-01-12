output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.lucidlink.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lucidlink.id
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.lucidlink.private_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i /Users/davidphillips/Documents/Cloud_PEMs/us-east-2.pem ubuntu@${aws_instance.lucidlink.public_ip}"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.main.id
}

output "route_table_id" {
  description = "The ID of the route table"
  value       = aws_route_table.main.id
}

output "vpc_endpoint_s3" {
  description = "The ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.main.id]  # Adjust this if you have multiple subnets
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.main.id]  # Adjust this if you have multiple subnets
}

output "instance_security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance.id
}
