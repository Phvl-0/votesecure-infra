resource "aws_s3_bucket" "backups" {
  #checkov:skip=CKV_AWS_18:Access logging needs a second bucket and nobody reads the logs in this lab
  #checkov:skip=CKV2_AWS_62:Nothing consumes bucket events
  #checkov:skip=CKV_AWS_144:Cross-region replication doubles storage cost; backups stay in one region, noted in the README
  #checkov:skip=CKV_AWS_145:AES256 encrypts the objects; a customer-managed KMS key adds a monthly cost
  bucket        = "votesecure-backups-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

data "aws_iam_policy_document" "vm_backups" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.backups.arn}/db/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups.arn]
  }
}

resource "aws_iam_role_policy" "vm_backups" {
  name   = "backups-bucket-access"
  role   = aws_iam_role.vm.name
  policy = data.aws_iam_policy_document.vm_backups.json
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}
