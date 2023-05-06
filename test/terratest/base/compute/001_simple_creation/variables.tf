variable "aksk_file" {
  type        = string
  description = "File for AK/SK (CSV-format as downloaded from Open Telekom Cloud)"
}

variable "domain_name" {
  type        = string
  description = "OTC Domain"
}

variable "tenant_name" {
  type        = string
  description = "OTC tenant (i.e. project name)"
}

variable "emergency_user_spec_public_key_file" {
  description = "This variable represents the public key file for the emergency user (default: empty string)."
  type = string
  default = ""
}
