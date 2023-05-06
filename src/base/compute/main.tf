##################################################################################
## Data sources
##################################################################################

# Retrieve OpenTelekomCloud image matching image_name variable
data "opentelekomcloud_images_image_v2" "otc_af_base_compute_image" {
  name = var.image_name
}

# Retrieve OpenTelekomCloud flavor matching flavor_name variable
data "opentelekomcloud_compute_flavor_v2" "otc_af_base_compute_flavor" {
  name = var.flavor_name
}

# Load security-related cloud-init configuration file as a template
data "template_file" "otc_af_base_compute_security_cloud_config" {
  template = file("${path.module}/cloud-init/security.yaml")
  vars = {
    ssh_pwauth = "false"
  }
}

# Load emergency user-related cloud-init configuration file as a template
data "template_file" "otc_af_base_compute_users_cloud_config" {
  template = !var.emergency_user ? "" : "${file("${path.module}/cloud-init/emergency_user.yaml")}"
  vars = {
    username        = var.emergency_user_spec_username
    gecos           = "Emergency user"
    lock_passwd     = true
    shell           = var.emergency_user_spec_shell
    groups          = "[ ${join(", ", var.emergency_user_spec_groups)} ]"
    sudo            = var.emergency_user_spec_sudo
    public_key_file = file(var.emergency_user_spec_public_key_file)
  }
}

# Load sshd configuration file as a template
data "template_file" "otc_af_base_compute_sshd_config" {
  template = file("${path.module}/cloud-init/sshd_config.yaml")
  vars = {
    allow_tcp_forwarding    = var.allow_tcp_forwarding ? "yes" : "no"
    client_alive_interval   = 180
    max_auth_tries          = 3
    password_authentication = "no"
    permit_empty_passwords  = "no"
    permit_root_login       = "no"
    protocol                = 2
  }
}

# Retrieve available availability zones
data "opentelekomcloud_compute_availability_zones_v2" "otc_af_base_compute_available_availability_zones" {}

# Retrieve current OpenTelekomCloud project
data "opentelekomcloud_identity_project_v3" "otc_af_base_compute_current_project" {}


##################################################################################
## Locals
##################################################################################

# This block defines local variables used to determine the availability zone to deploy instances in. 
# The region is determined from the current OpenTelekomCloud project region, while the availability 
# zone is either set to the user-specified value or defaults to the first availability zone in 
# the region. The `create` variable is used to control whether or not to create resources in 
# the OpenTelekomCloud platform.

locals {
  create            = var.create
  region            = data.opentelekomcloud_identity_project_v3.otc_af_base_compute_current_project.region
  availability_zone = var.availability_zone == "" ? "${local.region}-01" : var.availability_zone
}


##################################################################################
## Virtual Machine
##################################################################################

resource "opentelekomcloud_compute_instance_v2" "otc_af_base_compute" {
  # Determines whether the resource should be created or not.
  count               = local.create ? 1 : 0

  # Name of the node to be created.
  name                = var.name

  # Tags for the virtual machine
  tags                = var.tags

  # ID of the image to use, either retrieved by name via data-ressource or 
  # directly provided id by module user
  image_id            = var.image_id == "" ? data.opentelekomcloud_images_image_v2.otc_af_base_compute_image.id : var.image_id

  # ID of the flavor to use, either retrieved by name via data-ressource or 
  # directly provided id by module user 
  flavor_id           = var.flavor_id == "" ? data.opentelekomcloud_compute_flavor_v2.otc_af_base_compute_flavor.id : var.flavor_id

  # Availability zone where the node will be launched.
  availability_zone   = local.availability_zone

  # The following precondition checks if the availability zone
  # specified in the 'local.availability_zone' variable is included in the list of available availability zones in
  # the current region, using the 'data.opentelekomcloud_compute_availability_zones_v2' data source. If the condition is
  # not met, it will raise an error message containing details about the invalid setting. 
  lifecycle {
    precondition {
      condition     = contains(data.opentelekomcloud_compute_availability_zones_v2.otc_af_base_compute_available_availability_zones.names, local.availability_zone)
      error_message = "For node ${var.name}, availability zone setting is invalid. For the region ${local.region} the valid AZ's are ${jsonencode(data.opentelekomcloud_compute_availability_zones_v2.otc_af_base_compute_available_availability_zones.names)}"
    }
  }

  # The security group to associate with the node.
  # security_groups     = [opentelekomcloud_networking_secgroup_v2.otc_af_base_compute_securitygroup.name]

  # This code creates a user_data string to be passed to an OpenTelekomCloud instance. The
  # user_data is created by encoding and joining several cloud-init files, including
  # the provided configuration files and user data from variables. The 'sensitive'
  # keyword will mask the user_data in logs, preventing sensitive data leaks.
  user_data = base64encode(
    sensitive(
      join(
        "\n",
        [var.cloud_init_config],
        [data.template_file.otc_af_base_compute_security_cloud_config.rendered],
        [data.template_file.otc_af_base_compute_users_cloud_config.rendered],
        [data.template_file.otc_af_base_compute_sshd_config.rendered]
      )
    )
  )

  # primary subnet the virtual machine belongs to
  network {
    uuid           = var.network_subnet_id
    name           = var.network_subnet_id == null && var.network_port_id == null ? var.network_name : null
    port           = var.network_subnet_id == null && var.network_name == null ? var.network_port_id : null
    fixed_ip_v4    = var.create_public_ip ? null : var.network_fixed_ip_v4
    fixed_ip_v6    = var.create_public_ip ? null : var.network_fixed_ip_v6
    access_network = var.network_access_network
  }

  # Dynamic block for creating additional network interfaces for the instance
  # using the for_each meta-argument to create multiple instances of the block.
  # The block iterates over the map of additional network interfaces provided in
  # the variable var.network_additional_interfaces, and creates a content block
  # for each interface with attributes corresponding to the keys of each map item.
  dynamic "network" {
    for_each = var.network_additional_interfaces
    content {
      uuid           = lookup(each.value, "network_subnet_id", null)
      name           = lookup(each.value, "network_subnet_id", null) == null && lookup(each.value, "network_port_id", null) == null ? lookup(each.value, "network_name", null) : null
      port           = lookup(each.value, "network_subnet_id", null) == null && lookup(each.value, "network_name", null) == null ? lookup(each.value, "network_port_id", null) : null
      fixed_ip_v4    = lookup(each.value, "network_fixed_ip_v4", null)
      fixed_ip_v6    = lookup(each.value, "network_fixed_ip_v6", null)
      access_network = lookup(each.value, "network_access_network", null)
    }
  }

  # Define a block device as system disk  that will be attached to the server instance being created

  # Case 1: system disk defined by module user and reference id to existing disk given as argument
  dynamic "block_device" {
    for_each = var.system_disk_id == null || var.system_disk_id == "" ? [] : [1]
    content {
      uuid                  = var.system_disk_id
      source_type           = "image"
      boot_index            = 0
    }
  }

  # Case 2: No system disk created outside the module, hence system disk details defined 
  # created based on the given disk image id
  dynamic "block_device" {
    for_each = var.system_disk_id == null  || var.system_disk_id == "" ? [1] : []
    content {
      # Determine the image id based on the input value of "var.image_id" or by using the image id from the data source 
      # "data.opentelekomcloud_images_image_v2" if "var.image_id" is not specified
      uuid                  = var.image_id == "" ? data.opentelekomcloud_images_image_v2.otc_af_base_compute_image.id : var.image_id
      source_type           = "image"
      volume_size           = var.system_disk_size
      # Set the boot index to 0 to ensure that the instance boots from this block device
      boot_index            = 0
      destination_type      = "volume"
      # Set the "delete_on_termination" flag to true to ensure that the block device is deleted when the instance is terminated
      delete_on_termination = true
      volume_type           = var.system_disk_type
    }
  }


  # Create a dynamic block for defining additional disk devices, with the properties specified by 
  # the variables in var.disk_additional_devices. The for_each loop iterates over each value in the 
  # variable and creates a block with the specified properties for each value. The lookup function 
  # is used to retrieve the values of each property from the variable. If the property does not exist,
  # the respective variable will not be set
  dynamic "block_device" {
    for_each = var.disk_additional_devices
    content {
      uuid                  = lookup(each.value, "disk_id", null)
      source_type           = lookup(each.value, "disk_source_type", null) 
      volume_size           = lookup(each.value, "disk_volume_size", null) 
      boot_index            = lookup(each.value, "disk_bootable", null) == null || lookup(each.value, "disk_bootable", null) == false ? -1 : each.index + 1
      destination_type      = "volume"
      delete_on_termination = lookup(each.value, "disk_delete_on_termination", null)
      volume_type           = lookup(each.value, "disk_type", null)
    }
  }

  # Create additional ephemeral disk devices, with each block having specific properties based 
  # on values in the `var.disk_additional_ephemeral_devices` variable. The `volume_size` and 
  # `volume_type` properties are retrieved from the variable using the `lookup` function, 
  # with default values assigned if the property is not present. 
  dynamic "block_device" {
    for_each = var.disk_additional_ephemeral_devices
    content {
      source_type           = "blank" 
      volume_size           = lookup(each.value, "disk_volume_size", null) == null || lookup(each.value, "disk_volume_size", null) <= 0 ? 1 : lookup(each.value, "disk_volume_size", null) 
      boot_index            = -1
      destination_type      = "volume"
      delete_on_termination = true
      volume_type           = lookup(each.value, "disk_type", null) == null ? "SATA" : lookup(each.value, "disk_type", null)
    }
  }



}
