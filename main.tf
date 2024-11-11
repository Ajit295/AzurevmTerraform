#creation of Resource Group
resource "azurerm_resource_group" "AZ-305-RG" {
  name     = local.resource_group_name
  location = local.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "App-VNET" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = ["10.0.0.0/16"]
  depends_on = [ azurerm_resource_group.AZ-305-RG ]

}

# Create Subnets
resource "azurerm_subnet" "SubnetA" {
  name                 = local.subnet[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnet[0].address_prefix]
  depends_on = [ azurerm_resource_group.AZ-305-RG,
    azurerm_virtual_network.App-VNET
   ]

}

resource "azurerm_subnet" "SubnetB" {
  name                 = local.subnet[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnet[1].address_prefix]
  depends_on = [ azurerm_resource_group.AZ-305-RG,
    azurerm_virtual_network.App-VNET
   ]

}

# Create Public IP address
resource "azurerm_public_ip" "App-IP" {
  name                = "App-IP"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.AZ-305-RG ]

}

# Create Network Interface Card and associate Public IP address to NIC
resource "azurerm_network_interface" "App-Nic" {
  name                = "App-Nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.App-IP.id

  }

  depends_on = [ azurerm_resource_group.AZ-305-RG,
  azurerm_subnet.SubnetA ]
}

# Create NSG
resource "azurerm_network_security_group" "App-NSG" {
  name                = "App-NSG"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [ azurerm_resource_group.AZ-305-RG ]

}

# Link NSG to subnet
resource "azurerm_subnet_network_security_group_association" "subnet-NSG-Linking" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.App-NSG.id
  depends_on = [ azurerm_resource_group.AZ-305-RG,
  azurerm_subnet.SubnetA,
  azurerm_network_security_group.App-NSG ]
}

# Create Windows VM
resource "azurerm_windows_virtual_machine" "VM-1" {
  name                = "VM-1"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_B2s"
  admin_username      = "Ajit"
  admin_password      = "Adminuser@2954"
  network_interface_ids = [
    azurerm_network_interface.App-Nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [ azurerm_resource_group.AZ-305-RG, azurerm_network_interface.App-Nic ]
}
