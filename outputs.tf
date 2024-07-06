output "ipaddresse" {
   value = { for vm_id, details in local.vm_details : vm_id => details.ip_address }
  description = "The IP addresses of the VMs indexed by vm_id."
}