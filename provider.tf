terraform {
  backend "s3" {
    bucket = "mystatefilebackend1518"
    region   = "ap-south-1"
    key = "terraform.tfstatefile"
}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
  }
}

