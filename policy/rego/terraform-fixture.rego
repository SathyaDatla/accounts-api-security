package terraform

import rego.v1
deny contains msg if {
  input.kind == "Fixture"
  input.database.publicly_accessible == true
  msg := "T5: public database rejected"
}
deny contains msg if {
  input.kind == "Fixture"
  input.database.storage_encrypted == false
  msg := "T5: unencrypted database rejected"
}
