terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tf-dev-rg" {
  name     = "tf-dev-rg"
  location = "Germany West Central"
}


resource "azurerm_network_security_group" "tf-dev-nsg" {
  name                = "tf-dev-nsg"
  location            = azurerm_resource_group.tf-dev-rg.location
  resource_group_name = azurerm_resource_group.tf-dev-rg.name

  security_rule {
    name                       = "tf_Regeln-3389"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "tf_Regeln-443"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "tf_Regeln-22"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

resource "azurerm_virtual_network" "tf-vnet" {
  name                = "tf-vnet"
  location            = azurerm_resource_group.tf-dev-rg.location
  resource_group_name = azurerm_resource_group.tf-dev-rg.name
  address_space       = ["10.20.0.0/16"]
  dns_servers         = ["10.20.0.4", "10.20.0.5", "8.8.8.8"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.20.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.20.2.0/24"
  }
}

resource "azurerm_subnet" "subnet3" {
  name                 = "subnet3"
  address_prefixes     = ["10.20.3.0/24"]
  resource_group_name  = azurerm_resource_group.tf-dev-rg.name
  virtual_network_name = azurerm_virtual_network.tf-vnet.name
}

resource "azurerm_network_interface" "tf-nic" {
  name                = "tf-nic"
  location            = azurerm_resource_group.tf-dev-rg.location
  resource_group_name = azurerm_resource_group.tf-dev-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-ip-devops.id
  }
}
resource "azurerm_public_ip" "tf-ip-devops" {
  name                = "tf-ip-devops"
  resource_group_name = azurerm_resource_group.tf-dev-rg.name
  location            = azurerm_resource_group.tf-dev-rg.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_machine" "tf-ubuntu-test" {
  name                  = "tf-ubuntu-test"
  resource_group_name   = azurerm_resource_group.tf-dev-rg.name
  location              = azurerm_resource_group.tf-dev-rg.location
  network_interface_ids = [azurerm_network_interface.tf-nic.id]
  vm_size               = "Standard_bs1"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tf-ubuntu-vm"
    admin_username = "admingm"
  }

  admin_ssh_key {
    admin_username = "admingm"
    public_key     = file("~/ssh/tfubuntukey.pub")

  }

}