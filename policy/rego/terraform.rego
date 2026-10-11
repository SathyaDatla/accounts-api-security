package terraform

import rego.v1

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_db_instance"
  after := rc.change.after
  after.publicly_accessible == true
  msg := sprintf("T5: %s database must be private", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_db_instance"
  after := rc.change.after
  after.storage_encrypted == false
  msg := sprintf("T5: %s database storage must be encrypted", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_db_instance"
  after := rc.change.after
  after.backup_retention_period < 7
  msg := sprintf("T5: %s requires at least 7 days of backups", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_db_instance"
  after := rc.change.after
  after.deletion_protection == false
  msg := sprintf("T5: %s deletion protection must be enabled", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_db_instance"
  after := rc.change.after
  after.skip_final_snapshot == true
  msg := sprintf("T5: %s must retain a final snapshot", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_security_group_rule"
  after := rc.change.after
  after.cidr_blocks[_] == "0.0.0.0/0"
  after.from_port <= 5432
  after.to_port >= 5432
  msg := sprintf("T5: %s exposes PostgreSQL to the internet", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_cloudtrail"
  after := rc.change.after
  after.enable_log_file_validation == false
  msg := sprintf("T5: %s must validate log files", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_cloudtrail"
  after := rc.change.after
  after.is_multi_region_trail == false
  msg := sprintf("T5: %s must be multi-region", [rc.address])
}
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_cloudtrail"
  after := rc.change.after
  after.include_global_service_events == false
  msg := sprintf("T5: %s must include global service events", [rc.address])
}
