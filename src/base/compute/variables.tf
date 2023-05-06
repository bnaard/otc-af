##################################################################################
## General
##################################################################################

variable "create" {
  description = "Whether to create an instance.\nDefault: true"
  type        = bool
  default     = true
}

variable "name" {
  type        = string
  default     = "otc_ecs"
  description = "Name of virtual machine.\nDefault: \"otc_ecs\""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the virtual machine.\nFormat:\n  {\n    key1 = \"value1\",\n    key2 = \"value2\"\n    ...\n  }\nDefault: {}."
  default     = {}
}

variable "cloud_init_config" {
  description = "Cloud-init configuration (multi-line string) used as user-data.\nTo add own cloud-init files use a local variable to ceate a list of paths each containing cloud-init files:\n  locals {\n    cloud_init_files = flatten([\n      for path_to_cloud_init in <your_list_of_paths_to_cloud_init_files> : [\n        for path in fileset(\"\", \"$${path_to_cloud_init}/*.{yml,yaml}\") : path\n      ]\n    ])\n  }\nThen add the file-contents to this variable with a join-statement:\n  cloud_init_config = join(\"\\n\", [for filepath in local.cloud_init_files : file(filepath)])\nDefault: \"\""
  type        = string
  default     = ""
}

##################################################################################
## Virtual machine configuration
##################################################################################

variable "availability_zone" {
  type        = string
  description = "Availability zone for the virtual machine\nDefault: \"eu-de-01\""
  default     = "eu-de-01"
}

variable "flavor_id" {
  type        = string
  default     = ""
  description = "ID of the virtual machine's flavor type, in case the module user wants to determine the ID instead of providing the flavor name. Mutual exclusive with variable flavor_name.\nDefault: \"\""
}

variable "flavor_name" {
  type        = string
  default     = "s3.medium.1"
  description = "Name of the compute ressource type. Valid values see https://open-telekom-cloud.com/service-description, page 9  (default: \"s3.medium.1\")"
}

variable "image_id" {
  type        = string
  default     = ""
  description = "ID of the virtual machine's system disk image, in case the module user wants to determine the ID instead of providing the image name. Mutual exclusive with variable image_name.\nDefault: \"\""
}

variable "image_name" {
  type        = string
  default     = "Standard_Ubuntu_22.04_latest"
  description = "Name of the virtual machine's system disk image\nDefault: \"Standard_Ubuntu_22.04_latest\""
}



##################################################################################
## Network
##################################################################################

# Defines the ID of the network subnet that the server is attached to.
variable "network_subnet_id" {
  type        = string
  default     = ""
  description = "ID of the network subnet this virtual machine belongs to. Required unless port or name is provided. If subnet_id is provided, port or name contents are discarded.\ndefault: \"\""
}

# Defines the human-readable name of the network to attach to the server.
variable "network_name" {
  type        = string
  default     = ""
  description = "Human-readable name of the network to attach to the server. Required unless uuid or port is provided. If subnet_id is provided, port or name contents are discarded.\ndefault: \"\""
}

# Defines the port UUID of the network to attach to the server.
variable "network_port_id" {
  type        = string
  default     = ""
  description = "Port UUID of the network to attach to the server. Required unless uuid or name is provided. If subnet_id is provided, port or name contents are discarded.\ndefault: \"\""
}

# Defines a fixed IPv4 address to use on this network.
variable "network_fixed_ip_v4" {
  type        = string
  default     = null
  description = "Specifies a fixed IPv4 address to be used on this network. Optional. If create_public_ip == true, the settings for network_fixed_ip_v4 and network_fixed_ip_v6 will be ignored.\ndefault: \"\""
}

# Defines a fixed IPv6 address to use on this network.
variable "network_fixed_ip_v6" {
  type        = string
  default     = null
  description = "Specifies a fixed IPv6 address to be used on this network. Optional.If create_public_ip == true, the settings for network_fixed_ip_v4 and network_fixed_ip_v6 will be ignored.\ndefault: \"\""
}

# Specifies if the network should be used for provisioning access.
variable "network_access_network" {
  type        = bool
  default     = false
  description = "Specifies if this network should be used for provisioning access. Optional.\ndefault: false."
}

variable "network_additional_interfaces" {
  description = "Additional custom network interfaces to be attached at virtual machine boot time\nFormat:\n  [\n    {\n      \"network_subnet_id\": string = same as network_subnet_id variable.\n      \"network_name\": string = same as network_name variable,\n      \"network_port_id\": string = same as network_port_id variable,\n      \"network_fixed_ip_v4\": string = same network_fixed_ip_v4 variable,\n      \"network_fixed_ip_v6\": string = same as network_fixed_ip_v6 variable,\n      \"network_access_network\": string = same as network_access_network variable\n    }\n  ]\ndefault: []"
  type        = list(map(string))
  default     = []
}


variable "create_public_ip" {
  type        = bool
  default     = false
  description = "If true, creates a public IP, attaches it to the first network of the virtual machine and provides the IPv4 address as output. If create_public_ip == true, the settings for network_fixed_ip_v4 and network_fixed_ip_v6 will be ignored.\nDefault: false."
}

variable "public_ip_bandwidth" {
  description     = "Bandwidth of public IP access to the virtual machine in MBit.\nMust be between 1 and 300.\ndefault: 5"
  type            = number
  default         = 5
  validation {
    condition     = var.public_ip_bandwidth >= 1 && var.public_ip_bandwidth <= 300
    error_message = "Allowed values for public_ip_bandwidth >= 1 and <= 300."
  }
}

variable "public_ip_bandwidth_share_type" {
  description     = "Specifies whether the bandwidth is shared or dedicated.\nMust be one of \"WHOLE\" (Shared bandwidth) or \"PER\" (Dedicated bandwidth)\nDefault: \"PER\""
  type            = string
  default         = "PER"
  validation {
    condition     = contains(["WHOLE", "PER"], var.public_ip_bandwidth_share_type)
    error_message = "Allowed values for public_ip_bandwidth_share_type are \"WHOLE\" or \"PER\"."
  }
}



##################################################################################
## Attached block storage devices
##################################################################################

variable "system_disk_size" {
  type            = number
  default         = 10
  description     = "Size of the system disk for the virtual machine in GByte.If system_disk_id is set, system_disk_size and system_disk_type are ignored.\ndefault: 10"
  validation {
    condition     = var.system_disk_size > 0
    error_message = "Only values > 0 are allowed."
  }
}

variable "system_disk_type" {
  description     = "Virtual machine system disk storage type. The value can be \"SSD\" (ultra-I/O disk type), \"SAS\" (high I/O disk type), or \"SATA\" (common I/O disk type). If system_disk_id is set, system_disk_size and system_disk_type are ignored.\nDefault: \"SATA\""
  default         = "SSD"
  validation {
    condition     = contains(["SATA", "SAS", "SSD"], var.system_disk_type)
    error_message = "Allowed values for system_disk_type are \"SATA\", \"SAS\", or \"SSD\"."
  }
}

variable "system_disk_id" {
  type        = string
  default     = null
  description = "Optional reference to an existing block storage device, if system disk is created by module user. If system_disk_id is set, system_disk_size and system_disk_type are ignored.\nDefault: null"
}

variable "disk_additional_devices" {
  description = <<EOT
Additional custom block storage disks to be attached to the virtual machine at boot time.
Format:
  [
    {
      disk_source_type : string = (mandatory) One of "image", "volume", "snapshot" or "blank"
      disk_id : string = (mandatory) Dependent on disk_source_type, refers to an image-ID, a volume-ID or a snapshot-ID 
      disk_volume_size : number = (mandatory for disk_source_type = "image" or "blank") Non-zero, positive value defining the disk size in GByte.
      disk_delete_on_termination : bool (optional) Delete the volume / block device upon termination of the instance. Defaults to false. 
      disk_type : string (optional) The value can be "SSD" (ultra-I/O disk type), "SAS" (high I/O disk type), or "SATA" (common I/O disk type). Defaults to "SATA".
      disk_bootable : bool (optional) If true, the disk will get a boot index, otherwise not attempt to boot from. Defaults to false.
    }
  ]
  EOT
  type        = list(map(string))
  default     = []
}

variable "disk_additional_ephemeral_devices" {
  description = <<EOT
Additional ephemeral block storage devices added to the machine at boot-time. Disk cannot be booted from and will be deleted at termination.
Format:
  [
    {
      disk_volume_size : number = (optional) Non-zero, positive value defining the disk size in GByte. Defaults to 1 GByte.
      disk_type : string (optional) The value can be "SSD" (ultra-I/O disk type), "SAS" (high I/O disk type), or "SATA" (common I/O disk type). Defaults to "SATA".
    }
  ]
  EOT
  type        = list(map(string))
  default     = []
}



##################################################################################
## Emergency user
##################################################################################

variable "emergency_user" {
  description = "If set to *true*, a cloud-init config with an *emergency_ssh_key' for *emergency_user_spec* will be added (default: false)."
  type        = bool
  default     = false
}

variable "emergency_user_spec_username" {
  description = "This variable represents the username for an emergency user (default: \"emergency\")."
  type = string
  default = "emergency"
}

variable "emergency_user_spec_groups" {
  description = "This variable represents the groups that the emergency user belongs to (default: \"[\"users\", \"admin\", \"wheel\"]\")."
  type = list(string)
  default = ["users", "admin", "wheel"]
}

variable "emergency_user_spec_shell" {
  description = "This variable represents the shell that the emergency user will use (default: \"/bin/sh\")."
  type = string
  default = "/bin/sh"
}

variable "emergency_user_spec_sudo" {
  description = "This variable represents the sudo permissions for the emergency user (default: \"ALL=(ALL) NOPASSWD:ALL\")."
  type = string
  default = "ALL=(ALL) NOPASSWD:ALL"
}

variable "emergency_user_spec_public_key_file" {
  description = "This variable represents the public key file for the emergency user (default: empty string)."
  type = string
  default = ""
}


##################################################################################
## Security
##################################################################################

variable "allow_tcp_forwarding" {
  description   = "Enables (true) or disables (false) TCP forwarding, e.g. for using the virtual machine as jump host (default: false)"
  type          = bool
  default       = false
}
