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

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encrytion" {
  bucket = aws_s3_bucket.terraform-state.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_backend.arn
      sse_algorithm     = "aws.kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform-state.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "defaul_encription" {
  bucket = aws_s3_bucket.terraform-state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_backend.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.terraform-state.id
  acl    = "private"
}


resource "aws_dynamodb_table" "terraform-state" {
  name         = "backend-dynamodb-tf-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  point_in_time_recovery {
    enabled = true
  }
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }
  server_side_encryption {
    enabled = true
  }

}

resource "aws_kms_key" "s3_kms_backend" {
  description             = "Example Customer Managed Key"
  deletion_window_in_days = 10
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = <<EOF
                                {
                                  "Version": "2012-10-17",
                                  "Id": "key-default-1",
                                  "Statement": [
                                    {
                                      "Effect": "Allow",
                                      "Principal": {
                                        "Service": "s3.amazonaws.com"
                                      },
                                      "Action": [
                                        "kms:Encrypt",
                                        "kms:Decrypt",
                                        "kms:ReEncrypt*",
                                        "kms:GenerateDataKey*",
                                        "kms:DescribeKey"
                                      ],
                                      "Resource": "*"
                                    }
                                  ]
                                }
                              EOF
}

/*resource "aws_instance" "servidor" {
  instance_type = "t2.micro"
  ami           = "ami-05c13eab67c5d8861"
  iam_instance_profile = "test"

  tags = {
    Name       = var.tags
    Desplegado = "Terraform"
  }
}*/