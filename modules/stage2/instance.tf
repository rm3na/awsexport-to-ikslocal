
data "terraform_remote_state" "ovaurl" {
  backend = "remote"

  config = {
    hostname = "app.terraform.io"
    organization = "Nterone"
    workspaces = {
       name = "awsexport-to-istlocal-stage1"
    }
  }
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "random_string" "folder_name_prefix" {
  length    = 10
  min_lower = 10
  special   = false
  lower     = true

}


resource "vsphere_folder" "vm_folder" {
  path          =  "${var.vm_folder}-${random_string.folder_name_prefix.id}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Lets see something cool with Cisco Intersight & TFCB
resource "vsphere_virtual_machine" "vm_deploy" {
  name   = "AWS_IMPORT"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  datacenter_id = data.vsphere_datacenter.dc.id
  host_system_id = data.vsphere_host.host.id
  folder           = "AWS_IMPORTS"
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 0

ovf_deploy {
    remote_ovf_url = terraform_remote_state.ovaurl.exports3_url
    disk_provisioning = "thin"
    #ovf_network_map = {
    #  "sddc-cgw-network-1" = data.vsphere_network.network.id
  #  }
      network_interface {}
    }
  }

}
