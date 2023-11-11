terraform {
  backend "s3" {
    bucket = "backend-s3-tf-state"
    key    = "servidor/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "backend-dynamodb-tf-state"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "terraform-state" {
  bucket = "backend-s3-tf-state"
  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.terraform-state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_dynamodb_table" "terraform-state" {
  name         = "backend-dynamodb-tf-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "servidor" {
  instance_type = "t2.micro"
  ami           = "ami-05c13eab67c5d8861"

  tags = {
    Name       = var.tags
    Desplegado = "Terraform"
  }
}