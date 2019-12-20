resource "oci_core_virtual_network" "K8SVNC" {
  cidr_block     = var.VPC-CIDR
  compartment_id = var.compartment_ocid
  display_name = format("%s_%s",var.OKE_Network_name,var.Participant_Initials)
  dns_label      = "k8s"
}


resource "oci_core_internet_gateway" "K8SIG" {
  compartment_id = var.compartment_ocid
  display_name   = "K8S-IG"
  vcn_id         = oci_core_virtual_network.K8SVNC.id
}

resource "oci_core_route_table" "RouteForK8S" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.K8SVNC.id
  display_name   = "RouteTableForK8SVNC"

  route_rules {
    destination        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.K8SIG.id
  }
}

resource "oci_core_security_list" "WorkerSecList" {
  compartment_id = var.compartment_ocid
  display_name   = "WorkerSecList"
  vcn_id         = oci_core_virtual_network.K8SVNC.id

  ingress_security_rules {
    protocol = "all"
    source   = lookup(var.network_cidrs,"workerSubnetAD1")
    stateless = true
  }

  ingress_security_rules {
    protocol = "all"
    source   = lookup(var.network_cidrs,"workerSubnetAD2")
    stateless = true
   }

   ingress_security_rules {
     protocol = "all"
     source   = lookup(var.network_cidrs,"workerSubnetAD3")
     stateless = true
   }

   ingress_security_rules {
     protocol = "1"
     source   = "0.0.0.0/0"

     icmp_options {
       type = 3
       code = 4
       }
     stateless = false
   }

   ingress_security_rules {
     protocol = "6"
     source   = "130.35.0.0/16"
     stateless = false
     tcp_options {
       max = 22
       min = 22
       }
   }

   ingress_security_rules {
     protocol = "6"
     source   = "138.1.0.0/17"
     stateless = false
     tcp_options {
       max = 22
       min = 22
       }
   }

   ingress_security_rules {
     protocol = "6"
     source   = "0.0.0.0/0"
     stateless = false
     tcp_options {
       min = 30000
       max = 32767
       }
   }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  egress_security_rules {
    protocol = "all"
    destination   = lookup(var.network_cidrs,"workerSubnetAD1")
    stateless = true
  }

  egress_security_rules {
    protocol = "all"
    destination   = lookup(var.network_cidrs,"workerSubnetAD2")
    stateless = true
   }

   egress_security_rules {
     protocol = "all"
     destination   = lookup(var.network_cidrs,"workerSubnetAD3")
     stateless = true
   }

}

resource "oci_core_security_list" "LoadBalancerSecList" {
  compartment_id = var.compartment_ocid
  display_name   = "LoadBalancerSecList"
  vcn_id         = oci_core_virtual_network.K8SVNC.id

  ingress_security_rules {
     protocol = "6"
     source   = "0.0.0.0/0"
     stateless = true
   }

   ingress_security_rules {
     protocol = "6"
     source   = "0.0.0.0/0"
     stateless = false
     tcp_options {
       min = 80
       max = 80
       }
   }

   ingress_security_rules {
     protocol = "6"
     source   = "0.0.0.0/0"
     stateless = false
     tcp_options {
       min = 443
       max = 443
       }
   }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
    stateless = false
  }

}

resource "oci_core_subnet" "workerSubnet" {
  cidr_block          = lookup(var.network_cidrs, "workerSubnetAD1")
  display_name        = "workerSubnet"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.K8SVNC.id
  route_table_id      = oci_core_route_table.RouteForK8S.id
  security_list_ids   = [oci_core_security_list.WorkerSecList.id]
  dhcp_options_id     = oci_core_virtual_network.K8SVNC.default_dhcp_options_id
  dns_label           = "worker"
}

resource "oci_core_subnet" "LoadBalancerSubnet" {
  cidr_block          = lookup(var.network_cidrs, "LoadBalancerSubnetAD1")
  display_name        = "LoadBalancerSubnet"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.K8SVNC.id
  route_table_id      = oci_core_route_table.RouteForK8S.id
  security_list_ids   = [oci_core_security_list.LoadBalancerSecList.id]
  dhcp_options_id     = oci_core_virtual_network.K8SVNC.default_dhcp_options_id
  dns_label           = "loadbalancer"
}
