variable "vm_instances" {

    type = list(object({

        node_name = string
        url_cloud_init_img = string
        datastore_id = string
        user_cloud_init = string
        groups_cloud_init = string
        vm_name = string
        vm_id = number
        ip_addr = string
        cpu = number
        memory = number
        datastore_id_img = string
    }))

    default = []
    description = "VM instances list"
}


variable "url_proxmox" {
    type = string
}
variable "user_proxmox" {
    type = string
}
variable "password_proxmox" {
    type = string
    sensitive = true
}

# variable "datastore_id_img" {}



variable "ssh_key" {}