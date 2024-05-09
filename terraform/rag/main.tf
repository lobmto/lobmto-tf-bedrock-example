terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 0.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Configure the AWS Provider
provider "awscc" {
  region = "us-east-1"
}

variable "project_name" {
  type = string
}

module "knowledge_base" {
  source     = "../modules/knowledge_base"
  depends_on = [module.vector_db]

  project_name = var.project_name
  vector_db = {
    arn = module.vector_db.arn
  }
}

module "vector_db" {
  source       = "../modules/vector_db"
  project_name = var.project_name
}
