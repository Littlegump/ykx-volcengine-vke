# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  cloud { 
    
    organization = "volcengine-test" 

    workspaces { 
      name = "ykx-volcengine-vke" 
    } 
  } 
  required_providers {
      volcengine = {
          source = "volcengine/volcengine"
          version = "0.0.129"
      }
  }

  required_version = "~> 1.2"
}