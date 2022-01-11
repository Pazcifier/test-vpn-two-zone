variable "region" {
  description = "The region to create your two VPCs in, such as `us-south`. The VPCs are created in two separate zones within the same region. To get a list of all regions, run `ibmcloud is regions`."
  default = "us-south"
}


provider "ibm" {
  ibmcloud_timeout = 300
  generation = "1"
}
