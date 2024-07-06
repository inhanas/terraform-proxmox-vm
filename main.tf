provider "proxmox" {
    endpoint = var.url_proxmox
    username = var.user_proxmox
    password = var.password_proxmox
    ssh {
        agent = true
        username = "root"
    }
}

locals {
  vm_instances_map = { for vm in var.vm_instances : vm.vm_id => vm }
}

# locals {
#   ip_addr_only = { for vm in var.vm_instances : vm.vm_id => split("/", vm.ip_addr)[0] }
# }

locals {
  vm_details = { for vm in var.vm_instances : vm.vm_id => {
    ip_address = split("/", vm.ip_addr)[0],
    user       = vm.user_cloud_init
  }}
}

# resource "proxmox_virtual_environment_download_file" "cloud_init_image" {

#   for_each = local.vm_instances_map

#   content_type = "iso"
#   datastore_id = each.value.datastore_id_img
#   node_name    = each.value.node_name
#   url = each.value.url_cloud_init_img
# }

data "local_file" "ssh_public_key" {
  filename = "${path.module}/id_rsa.pub"
}



resource "proxmox_virtual_environment_vm" "create_vm" {

# à commenter si besoin de modifier la clé ssh ou disk mais àa va supprimer et recéer la ressource
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys,
      disk,
      vga,
    ]
  }


  for_each = local.vm_instances_map
  name      = each.value.vm_name
  node_name = each.value.node_name
  vm_id = each.value.vm_id
  
  initialization {

    user_account {
      keys = [trimspace(data.local_file.ssh_public_key.content)]
      password = each.value.user_cloud_init
      username = "ansible"
    }


    ip_config {
      ipv4 {
        address = each.value.ip_addr
        gateway = "192.168.1.254"
      }
    }
  }
  clone {
    vm_id = "900"
  }
  agent {
    enabled = false
  }
  cpu {
    cores = each.value.cpu
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = each.value.datastore_id
    # file_id      = proxmox_virtual_environment_download_file.cloud_init_image[each.key].id
    interface    = "virtio0"
    file_format = "raw"
    iothread     = true
    discard      = "on"
    size         = 20
  }
  network_device {
    bridge = "vmbr0"
  }
 
}

resource "null_resource" "sleep60s" {
  provisioner "local-exec" {
    command = "sleep 60s"
  }
  depends_on = [ proxmox_virtual_environment_vm.create_vm ]
}

resource "null_resource" "config_cloud_init" {

    for_each = local.vm_details
    
  
    connection {
        host        = each.value.ip_address
        user        = each.value.user
        private_key = file(var.ssh_key)
    }
    provisioner "file" {
        destination = "/tmp/cloud.cfg"
        source      = "${path.module}/cloud.cfg"
    }
  

    provisioner "remote-exec" {
    inline = [
        "sudo cp /tmp/cloud.cfg /etc/cloud/cloud.cfg"
    ]
    }
  depends_on = [ null_resource.sleep60s]
}