output "public_ip" {
  value       = [for node in module.otc_af_base_compute_test_01_basic_creation : try(node.public_ip, "")] 
}

output "access_ip_v4" {
  value       = [for node in module.otc_af_base_compute_test_01_basic_creation : try(node.access_ip_v4, "")] 
}
