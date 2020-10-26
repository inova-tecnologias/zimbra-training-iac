# Terraform Module - AWS - Zimbra Training

Terraform Module for provisioning all infrastructure needed for zimbra training in AWS CLOUD

- VPC and Networking
- Security Group
- Dedicated SSH KEY
- VM1 AND VM2 for day01 and day03 exercises
- DNS configuration on top of route 53

#### Terraform: v0.13.5

## Get Started

- Download [terraform](https://www.terraform.io/downloads.html)
- Create a main.tf file. Example:
```hcl
# main.tf
module "zimbra-training" {
  source = "github.com/inova-tecnologias/zimbra_training_iac"

  customer_name = "MyCustomer"
  participants = 10
  training_zone = "lab.example.com"
  tags = {
    "Owner": "Leonardo"
  }
}
```

### Provisioning
```sh
terraform init
terraform apply
```
That will generate the networking and DNS entries for each participant and a the private key that would be used for access that training machines.

To get the ssh_key:
```sh
terraform output -json | jq .ssh_key.value --raw-output
```


### Creating vms
- On module call set `vm1 = true` for creating the vms for the day01 exercise
- On module call set `vm2 = true` for creating the vms for the day03 exercise
- Than run `terraform apply`
- Example:
```hcl
# main.tf
module "zimbra-training" {
  source = "github.com/inova-tecnologias/zimbra_training_iac"

  customer_name = "MyCustomer"
  participants = 10
  training_zone = "lab.example.com"
  vm1 = true
  vm2 = true # Leave blank or false if its the first day of training
}
```


### Variables
|  Name       | Type |Required| Default |
|:-----------:|:----:|:------:|:-------:|
|customer_name|string|  true  |   N/A   |
|participants|number|true|N/A|
|training_zone|string|true|N/A|
|vm1|bool|false|false|
|vm2|bool|false|false|
|tags|map|false|{}|
|region|string|false|us-west-2|
|zports|list(number)|false|[22, 80, 110, 143,587, 993, 995, 7071]|
|instance|map|false|{"ami"="ami-fa9a1382","type"="t3.large"}

### Destroy after training:
`terraform destroy`