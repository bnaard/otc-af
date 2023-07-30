locals {
  aksk_csv_file_content = csvdecode(file(var.aksk_file))
  ak                    = local.aksk_csv_file_content[0]["Access Key Id"]
  sk                    = local.aksk_csv_file_content[0]["Secret Access Key"]
}

# Configure the OpenTelekomCloud Provider
provider "opentelekomcloud" {
  access_key  = local.ak
  secret_key  = local.sk
  domain_name = var.domain_name
  tenant_name = var.tenant_name
  auth_url    = "https://iam.eu-de.otc.t-systems.com/v3"
}

resource "opentelekomcloud_vpc_v1" "test_vpc" {
  name = "otc_af_base_compute_test_vpc"
  cidr = "192.168.0.0/16"
  tags = { deployment = "otc_af_base_compute_test", environment = "test", function = "vpc" }
}

resource "opentelekomcloud_vpc_subnet_v1" "test_subnet" {
  name       = "otc_af_base_compute_test_subnet"
  vpc_id     = opentelekomcloud_vpc_v1.test_vpc.id
  cidr       = "192.168.1.0/24"
  gateway_ip = cidrhost("192.168.1.0/24", 1) #  "192.168.1.1"
  tags       = { deployment = "otc_af_base_compute_test", environment = "test", function = "subnet" }
}





module "otc_af_base_compute_test_01_basic_creation" {
  count                               = 1
  # source                              = "git::https://github.com/bnaard/otc-af.git?ref=v0.1.0"
  source                              = "../../../../src/base/compute"
  name                                = "otc_af_base_compute_test_01_basic_creation"
  tags                                = { deployment = "otc_af_base_compute_test", environment = "test_01_basic_creation", function = "compute" }
  network_subnet_id                   = opentelekomcloud_vpc_subnet_v1.test_subnet.id
  create_public_ip                    = true
  availability_zone                   = "eu-de-01"
  flavor_name                         = "s3.medium.2"
  image_name                          = "Standard_Ubuntu_22.04_latest"
  emergency_user                      = true
  emergency_user_spec_public_key_file = var.emergency_user_spec_public_key_file
}

# resource "opentelekomcloud_networking_secgroup_rule_v2" "otc_af_base_compute_test_01_basic_creation_ssh_ingress_allow_rule" {
#   for_each = toset(["0.0.0.0/0"])

#   description       = "SSH allowed origins from Internet"
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_ip_prefix  = length(split("/", each.value)) == 2 ? each.value : "${each.value}/32"
#   security_group_id = module.otc_af_base_compute_test_01_basic_creation[0].security_group.id
# }


# resource "opentelekomcloud_networking_secgroup_rule_v2" "otc_af_base_compute_test_01_basic_creation_ssh_egress_allow_rule" {
#   description       = "Allow all outgoing communication from the node to internet."
#   direction         = "egress"
#   ethertype         = "IPv4"
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = module.otc_af_base_compute_test_01_basic_creation[0].security_group.id
# }
