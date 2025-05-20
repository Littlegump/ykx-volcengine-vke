# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }



variable "ak" { }
variable "sk" { }
provider "volcengine" {
  access_key = var.ak
  secret_key = var.sk
  region = var.volc_region
}

# 查询region中的azs
data "volcengine_zones" "foo" {
}

resource "volcengine_vpc" "foo" {
  vpc_name = var.vpc_name
  cidr_block = var.vpc_cidr_block
}

resource "volcengine_subnet" "puba" {
  subnet_name = "sn-pub-A"
  cidr_block  = "172.16.0.0/24"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "pria" {
  subnet_name = "sn-pri-A"
  cidr_block  = "172.16.1.0/24"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "pubb" {
  subnet_name = "sn-pub-B"
  cidr_block  = "172.16.2.0/24"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "prib" {
  subnet_name = "sn-pri-B"
  cidr_block  = "172.16.3.0/24"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "pubc" {
  subnet_name = "sn-pub-C"
  cidr_block  = "172.16.4.0/24"
  zone_id     = data.volcengine_zones.foo.zones[2].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "pric" {
  subnet_name = "sn-pri-C"
  cidr_block  = "172.16.5.0/24"
  zone_id     = data.volcengine_zones.foo.zones[2].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_security_group" "foo" {
  security_group_name = "ykx-volcengine-vke-sg"
  vpc_id              = volcengine_vpc.foo.id
}

// create vke cluster
resource "volcengine_vke_cluster" "foo" {
  name                      = "ykx-volcengine-vke"
  #description               = "created by terraform @ykx"
  delete_protection_enabled = false
  cluster_config {
    subnet_ids              = [volcengine_subnet.pria.id, volcengine_subnet.prib.id, volcengine_subnet.pric.id]
    api_server_public_access_enabled = true
    api_server_public_access_config {
      public_access_network_config {
        billing_type = "PostPaidByBandwidth"
        bandwidth    = 1
      }
    }
    resource_public_access_default_enabled = true
  }
  pods_config {
    pod_network_mode = "VpcCniShared"
    vpc_cni_config {
      subnet_ids        = [volcengine_subnet.puba.id, volcengine_subnet.pubb.id, volcengine_subnet.pubc.id]
    }
  }
  services_config {
    service_cidrsv4 = ["172.30.148.0/22"]
  }

  tags {
    key   = "env"
    value = "test"
  }
}

data "volcengine_images" "foo" {
  name_regex = "veLinux 1.0 CentOS Compatible 64 bit"
}


resource "volcengine_vke_node_pool" "foo" {
  cluster_id = volcengine_vke_cluster.foo.id
  name       = "ykx-volc-node-pool"
  auto_scaling {
    enabled          = true
    min_replicas     = 0
    max_replicas     = 5
    desired_replicas = 0
    priority         = 5
    subnet_policy    = "ZoneBalance"
  }
  node_config {
    instance_type_ids = ["ecs.g1ie.large"]
    subnet_ids        = [volcengine_subnet.puba.id, volcengine_subnet.pubb.id, volcengine_subnet.pubc.id]
    image_id          = [for image in data.volcengine_images.foo.images : image.image_id if image.image_name == "veLinux 1.0 CentOS Compatible 64 bit"][0]
    system_volume {
      type = "ESSD_PL0"
      size = 40
    }
    data_volumes {
      type        = "ESSD_PL0"
      size        = 100
      mount_point = "/tf1"
    }
    initialize_script = "ZWNobyBoZWxsbyB0ZXJyYWZvcm0h"
    security {
      login {
        ssh_key_pair_name = "key-for-ykx"
      }
      security_strategies = ["Hids"]
      security_group_ids  = [volcengine_security_group.foo.id]
    }
    additional_container_storage_enabled = false
    instance_charge_type                 = "PostPaid"
    name_prefix                          = "ykx-test"
    ecs_tags {
      key   = "env"
      value = "test"
    }
  }
  kubernetes_config {
    labels {
      key   = "env"
      value = "test"
    }
    cordon             = true
  }
  tags {
    key   = "env"
    value = "test"
  }
}

resource "volcengine_ecs_instance" "foo" {
  instance_name        = "ykx-test-ecs-${count.index}"
  host_name            = "ykx-volc-vke-test"
  image_id             = [for image in data.volcengine_images.foo.images : image.image_id if image.image_name == "veLinux 1.0 CentOS Compatible 64 bit"][0]
  instance_type        = "ecs.g1ie.large"
  #password             = "93f0cb0614Aab12"
  key_pair_name       = "key-for-ykx"
  instance_charge_type = "PostPaid"
  system_volume_type   = "ESSD_PL0"
  system_volume_size   = 50
  data_volumes {
    volume_type          = "ESSD_PL0"
    size                 = 50
    delete_with_instance = true
  }
  subnet_id          = volcengine_subnet.puba.id
  security_group_ids = [volcengine_security_group.foo.id]
  project_name       = "default"
  tags {
    key   = "env"
    value = "test"
  }
  lifecycle {
    ignore_changes = [security_group_ids, tags]
  }
  count = 2
}


# resource "volcengine_security_group" "foo" {
  # security_group_name = "sg-web-A"
  # vpc_id              = volcengine_vpc.foo.id
# }

# resource "volcengine_security_group_rule" "allowssh" {
#   direction         = "ingress"
#   security_group_id = volcengine_security_group.foo.id
#   protocol          = "tcp"
#   port_start        = 22
#   port_end          = 22
#   cidr_ip           = "0.0.0.0/0"
#   priority          = 1
#   policy            = "accept"
#   description       = "allow ssh login"
# }


# 请求 匹配指定实例类型的 image_id， 
#data "volcengine_images" "foo" {
#  os_type          = "Linux"
#  visibility       = "public"
#  instance_type_id = "ecs.g1ie.large"
#}
#
// create ecs instance
#resource "volcengine_ecs_instance" "foo" {
#  instance_name        = "ykx-test-ecs"
#  # description          = "ykx-test"
#  # host_name            = "ykx-test" # 可选
#  image_id             = data.volcengine_images.foo.images[0].image_id
#  instance_type        = data.volcengine_images.foo.instance_type_id
#  # password             = "93f0cb0614Aab12"
#  key_pair_name        = "key-for-ykx" 
#  instance_charge_type = "PostPaid"
#  system_volume_type   = "ESSD_PL0"
#  system_volume_size   = 40
#  subnet_id            = volcengine_subnet.web.id
#  security_group_ids   = [volcengine_security_group.foo.id]
#  project_name         = "default"
#  tags {
#    key   = "env"
#    value = "test"
#  }
#}
#
#resource "volcengine_eip_address" "foo" {
#  billing_type = "PostPaidByBandwidth"  # | PostPaidByTraffic  (按带宽上限，按实际流量)
#  bandwidth    = 1    # metric is Mbps
#  # the value can be BGP or ChinaMobile or ChinaUnicom or ChinaTelecom or SingleLine_BGP or Static_BGP or Fusion_BGP.
#  isp          = "BGP"
#  name         = "ykx-test-eip1"
#  description  = "acc-test"
#  project_name = "default"
#  tags {
#    key = "env"
#    value = "test"
#  }
#}
#resource "volcengine_eip_associate" "foo" {
#  allocation_id = volcengine_eip_address.foo.id
#  instance_id   = volcengine_ecs_instance.foo.id
#  instance_type = "EcsInstance"  # 可以是Nat, NetworkInterface or ClbInstance or EcsInstance or HaVip
#}