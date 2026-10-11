variable "private_subnet_ids" {
  description = "Private ap-south-1 database subnet IDs."
  type        = list(string)
}
variable "app_security_group_id" { type = string }
variable "db_security_group_id" { type = string }
variable "kms_key_arn" { type = string }
variable "cloudtrail_bucket_name" { type = string }
