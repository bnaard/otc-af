
# # Define a new OpenTelekomCloud security group resource with name and description
# resource "opentelekomcloud_networking_secgroup_v2" "otc_af_base_compute_securitygroup" {
#   name                 = "${var.name}_security_group"
#   description          = "Security group for the node ${var.name}"
  
#   # Remove default security group rules for the created security group
#   delete_default_rules = true
# }
