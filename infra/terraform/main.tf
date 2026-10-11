terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = "ap-south-1" }


resource "aws_db_subnet_group" "accounts" {
  name       = "accounts-prod"
  subnet_ids = var.private_subnet_ids
  tags = { DataClass = "Restricted", Threat = "T5" }
}

resource "aws_db_instance" "accounts" {
  identifier                  = "accounts-prod"
  engine                      = "postgres"
  instance_class              = "db.r6g.large"
  allocated_storage           = 100
  storage_encrypted           = true
  kms_key_id                  = var.kms_key_arn
  manage_master_user_password = true
  username                    = "accounts_master"
  db_subnet_group_name        = aws_db_subnet_group.accounts.name
  vpc_security_group_ids      = [var.db_security_group_id]
  publicly_accessible         = false
  backup_retention_period     = 14
  deletion_protection         = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "accounts-prod-final"
  auto_minor_version_upgrade  = true
  multi_az                    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  tags = { DataClass = "Restricted", Threat = "T5" }
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
  security_group_id        = var.db_security_group_id
  description              = "T5: PostgreSQL only from accounts-api security group"
}

resource "aws_ecr_repository" "accounts_api" {
  name                 = "accounts-api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
  tags = { Threat = "T2" }
}

resource "aws_cloudtrail" "org" {
  name                          = "org-trail"
  is_organization_trail         = true
  s3_bucket_name                = var.cloudtrail_bucket_name
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  enable_logging                = true
  kms_key_id                    = var.kms_key_arn
  depends_on                    = [aws_s3_bucket_policy.trail, aws_s3_bucket_versioning.trail, aws_s3_bucket_object_lock_configuration.trail, aws_s3_bucket_server_side_encryption_configuration.trail, aws_s3_bucket_public_access_block.trail]
}
resource "aws_s3_bucket_policy" "trail" {
  bucket = var.cloudtrail_bucket_name
  policy = data.aws_iam_policy_document.trail.json
}
data "aws_iam_policy_document" "trail" {
  statement {
    sid = "CloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.cloudtrail_bucket_name}/AWSLogs/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ap-south-1:123456789012:trail/org-trail"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid = "CloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${var.cloudtrail_bucket_name}"]
  }
}

resource "aws_s3_bucket" "trail" {
  bucket              = var.cloudtrail_bucket_name
  object_lock_enabled = true
  force_destroy       = false
  tags = { DataClass = "Audit", Threat = "T5" }
}
resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_object_lock_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}
resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
