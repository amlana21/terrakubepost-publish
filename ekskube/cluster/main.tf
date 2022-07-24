provider "aws" {
  region = local.region
}

locals {
  name            = var.cluster_name
  cluster_version = "1.21"
  region          = "us-east-1"

  tags = {
    Name    = local.name
  }
}

data "terraform_remote_state" "network_state" {
  backend = "s3"
  config= {
    bucket = "${var.state_bucket}"
    region = "${var.state_region}"
    key = "${var.state_key}"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.7.2"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = data.terraform_remote_state.network_state.outputs.cluster_vpc_id
  subnet_ids = data.terraform_remote_state.network_state.outputs.cluster_private_subnets

  eks_managed_node_groups = {
    grp1 = {
      desired_size = 1

      instance_types = ["t2.small"]
      labels = {
        Name    = "managed_node_groups"
      }
      tags = {
        ExtraTag = "grp1"
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        
        {
          namespace = "default"
          labels = {
            WorkerType = "fargate"
          }
        },
        {
          namespace = "monitoring"
          labels = {
            WorkerType = "fargate"
          }
        },
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        }
      ]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    secondary = {
      name = "secondary"
      selectors = [
        {
          namespace = "default"
          labels = {
            Environment = "dev"
          }
        }
      ]

      
      subnet_ids = [data.terraform_remote_state.network_state.outputs.cluster_private_subnets[1]]

      tags = {
        Owner = "secondary"
      }
    }
  }

  tags = local.tags
}