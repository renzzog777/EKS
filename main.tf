#------------------------------------------Declaración de Proveedores------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}
provider "aws" {
  region = var.region
}

#-----------------------------------------------VPC-------------------------------------

resource "aws_vpc" "VPC" {

  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  enable_dns_hostnames = true
}

# ----------------------------------------------PUBLIC SUBNETS----------------------------


resource "aws_subnet" "Public_Zone_A" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a" 
  map_public_ip_on_launch = true
}

resource "aws_subnet" "Public_Zone_B" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b" 
  map_public_ip_on_launch = true
}

#---------------------------------------------PRIVATE SUBNETS-----------------------------------------

resource "aws_subnet" "Private_Zone_A" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2a" 
}

resource "aws_subnet" "Private_Zone_B" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b" 
}


#-----------------------------------------------ROUTE TABLES------------------------------------------

#------------------------------------------------PUBLIC SUBNETS--------------------------------------
resource "aws_route_table" "Public_Routes" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

}

resource "aws_route_table_association" "Public_Zone_A_Association" {
  subnet_id      = aws_subnet.Public_Zone_A.id
  route_table_id = aws_route_table.Public_Routes.id
}

resource "aws_route_table_association" "Public_Zone_B_Association" {
  subnet_id      = aws_subnet.Public_Zone_B.id
  route_table_id = aws_route_table.Public_Routes.id
}

#------------------------------------------------PRIVATE SUBNETS---------------------------------------

resource "aws_route_table" "Private_Routes_1" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT1.id
  }
}

resource "aws_route_table_association" "Private_Zone_A_Association" {
  subnet_id      = aws_subnet.Private_Zone_A.id
  route_table_id = aws_route_table.Private_Routes_1.id
}

resource "aws_route_table" "Private_Routes_2" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT2.id
  }
}

resource "aws_route_table_association" "Private_Zone_B_Association" {
  subnet_id      = aws_subnet.Private_Zone_B.id
  route_table_id = aws_route_table.Private_Routes_2.id
}


#----------------------------------------------Elastic IP---------------------------------------------

resource "aws_eip" "IP1" {
  vpc = true
}

resource "aws_eip" "IP2" {
  vpc = true
}

#-------------------------------------POLITICAS------------------------------------------

# ------------------------------------  CLUSTER -----------------------------------------

resource "aws_iam_role" "Cluster_Role" {
  name = "Cluster-Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "Cluster_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.Cluster_Role.name
}

#-------------------Cluster EKS----------------------

resource "aws_eks_cluster" "Kubernetes_Cluster" {
  name     = "Kubernetes-Cluster"
  role_arn = aws_iam_role.Cluster_Role.arn


#------------------------------------------------SUBNETS-------------------------------
  vpc_config {
    subnet_ids = [
      aws_subnet.Public_Zone_A.id,
      aws_subnet.Public_Zone_B.id,
      aws_subnet.Private_Zone_A.id,
      aws_subnet.Private_Zone_B.id
    ]
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.Cluster_Policy,
    
  ]
}



#-------------------------------------------ADD-ONS RECOMENDADOS POR AWS----------------------
resource "aws_eks_addon" "eks_vpc_cni" {
  cluster_name = aws_eks_cluster.Kubernetes_Cluster.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "eks_vpc_core_dns" {
  cluster_name = aws_eks_cluster.Kubernetes_Cluster.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "eks_vpc_kube_proxy" {
  cluster_name = aws_eks_cluster.Kubernetes_Cluster.name
  addon_name   = "kube-proxy"
}



#--------------------------------------NODOS----------------------------------------------

resource "aws_iam_role" "Nodes_Role" {
  name = "Nodes-Role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "To_Worker_Node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.Nodes_Role.name
}

resource "aws_iam_role_policy_attachment" "To_CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.Nodes_Role.name
}

resource "aws_iam_role_policy_attachment" "To_Registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.Nodes_Role.name
}




#--------------------------------NODOS-----------------------------------------

resource "aws_eks_node_group" "Nodos" {
  cluster_name    = aws_eks_cluster.Kubernetes_Cluster.name
  node_group_name = "Nodos"
  node_role_arn   = aws_iam_role.Nodes_Role.arn
  subnet_ids      = [aws_subnet.Private_Zone_A.id, aws_subnet.Private_Zone_B.id]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.To_Worker_Node,
    aws_iam_role_policy_attachment.To_CNI,
    aws_iam_role_policy_attachment.To_Registry,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

}



# -----------------------------------------IG ---------------------------------------------

resource "aws_internet_gateway" "Internet_Gateway" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    Name = "Internet Gateway"
  }
}

#------------------------------------------NAT GW------------------------------------------

resource "aws_nat_gateway" "NAT1" {
  allocation_id = aws_eip.IP1.id
  subnet_id     = aws_subnet.Public_Zone_A.id
  depends_on = [aws_internet_gateway.Internet_Gateway]
}

resource "aws_nat_gateway" "NAT2" {
  allocation_id = aws_eip.IP2.id
  subnet_id     = aws_subnet.Public_Zone_B.id
  depends_on = [aws_internet_gateway.Internet_Gateway]
}
