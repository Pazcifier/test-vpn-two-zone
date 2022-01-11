resource "random_id" "name1" {
  byte_length = 2
}

resource "random_id" "name2" {
  byte_length = 2
}

locals {
     ZONE1     = "${var.region}-1"
     ZONE2     = "${var.region}-2"
   }


resource "ibm_is_vpc" "vpc1" {
  name = "vpc-region-1"
}

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet1-region-1"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${local.ZONE1}"
  total_ipv4_address_count = 256

  provisioner "local-exec" {
    command = "sleep 300"
    when    = "destroy"
  }
}

resource "ibm_is_vpn_gateway" "VPNGateway1" {
  name   = "vpn-region-1"
  subnet = "${ibm_is_subnet.subnet1.id}"
}

resource "ibm_is_vpn_gateway_connection" "VPNGatewayConnection1" {
  name          = "vpnconn-region-1"
  vpn_gateway   = "${ibm_is_vpn_gateway.VPNGateway1.id}"
  peer_address  = "${ibm_is_vpn_gateway.VPNGateway1.public_ip_address}"
  preshared_key = "VPNDemoPassword"
  local_cidrs   = ["${ibm_is_subnet.subnet1.ipv4_cidr_block}"]
  peer_cidrs    = ["${ibm_is_subnet.subnet2.ipv4_cidr_block}"]
  ipsec_policy  = "${ibm_is_ipsec_policy.example.id}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "${var.ssh_key_name}"
  public_key = "${var.ssh_public_key}"
}

resource "ibm_is_instance" "instance1" {
  name    = "instance-region-1"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    port_speed = "1000"
    subnet     = "${ibm_is_subnet.subnet1.id}"
  }

  vpc       = "${ibm_is_vpc.vpc1.id}"
  zone      = "${local.ZONE1}"
  keys      = ["${ibm_is_ssh_key.sshkey.id}"]
  user_data = "${file("nginx.sh")}"
}

resource "ibm_is_floating_ip" "floatingip1" {
  name   = "fip-region-1"
  target = "${ibm_is_instance.instance1.primary_network_interface.0.id}"
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg1_icmp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  icmp = {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "sg1_app_tcp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_vpc" "vpc2" {
  name = "vpc-region-2"
}

resource "ibm_is_subnet" "subnet2" {
  name            = "subnet2-region-2"
  vpc             = "${ibm_is_vpc.vpc2.id}"
  zone            = "${local.ZONE2}"
  total_ipv4_address_count = 256

  provisioner "local-exec" {
    command = "sleep 300"
    when    = "destroy"
  }
}

resource "ibm_is_ipsec_policy" "example" {
  name                     = "test-ipsec-region-2"
  authentication_algorithm = "md5"
  encryption_algorithm     = "3des"
  pfs                      = "disabled"
}

resource "ibm_is_ike_policy" "example" {
  name                     = "test-ike-region-2"
  authentication_algorithm = "md5"
  encryption_algorithm     = "3des"
  dh_group                 = 2
  ike_version              = 1
}

resource "ibm_is_vpn_gateway" "VPNGateway2" {
  name   = "vpn-region-2"
  subnet = "${ibm_is_subnet.subnet2.id}"
}

resource "ibm_is_vpn_gateway_connection" "VPNGatewayConnection2" {
  name           = "vpnconn-region-2"
  vpn_gateway    = "${ibm_is_vpn_gateway.VPNGateway2.id}"
  peer_address   = "${ibm_is_vpn_gateway.VPNGateway2.public_ip_address}"
  preshared_key  = "VPNDemoPassword"
  local_cidrs    = ["${ibm_is_subnet.subnet2.ipv4_cidr_block}"]
  peer_cidrs     = ["${ibm_is_subnet.subnet1.ipv4_cidr_block}"]
  admin_state_up = true
  ike_policy     = "${ibm_is_ike_policy.example.id}"
}

resource "ibm_is_instance" "instance2" {
  name    = "instance-region-2"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    port_speed = "1000"
    subnet     = "${ibm_is_subnet.subnet2.id}"
  }

  vpc       = "${ibm_is_vpc.vpc2.id}"
  zone      = "${local.ZONE2}"
  keys      = ["${ibm_is_ssh_key.sshkey.id}"]
  user_data = "${file("nginx.sh")}"
}

resource "ibm_is_floating_ip" "floatingip2" {
  name   = "fip-region-2"
  target = "${ibm_is_instance.instance2.primary_network_interface.0.id}"
}

resource "ibm_is_security_group_rule" "sg2_tcp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip2"]
  group      = "${ibm_is_vpc.vpc2.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg2_icmp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip2"]
  group      = "${ibm_is_vpc.vpc2.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  icmp = {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "sg2_app_tcp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip2"]
  group      = "${ibm_is_vpc.vpc2.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}
