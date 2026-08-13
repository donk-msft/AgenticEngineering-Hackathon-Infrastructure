metadata description = 'Private bootstrap VM and Azure Bastion Developer access for the Contoso Ticketing workload, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Subnet that hosts the private bootstrap VM.')
param bootstrapSubnetId string

@description('Virtual network used by Azure Bastion Developer.')
param virtualNetworkId string

@description('Log Analytics workspace used for VM diagnostics.')
param logAnalyticsWorkspaceId string

@description('Linux administrator username for the bootstrap VM.')
param adminUsername string

@description('SSH public key for the bootstrap VM administrator. Keep the matching private key outside source control.')
param adminSshPublicKey string

var suffix = '${workload}-${environment}-${location}'
var vmName = 'vm-bootstrap-${suffix}'
var bastionName = 'bas-${suffix}'

module bootstrapVm 'br/public:avm/res/compute/virtual-machine:0.22.0' = {
  name: 'vm-bootstrap-${suffix}'
  params: {
    availabilityZone: -1
    name: vmName
    location: location
    tags: tags
    vmSize: 'Standard_B1s'
    osType: 'Linux'
    adminUsername: adminUsername
    disablePasswordAuthentication: true
    imageReference: {
      publisher: 'Canonical'
      offer: '0001-com-ubuntu-server-jammy'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    publicKeys: [
      {
        keyData: adminSshPublicKey
        path: '/home/${adminUsername}/.ssh/authorized_keys'
      }
    ]
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: bootstrapSubnetId
          }
        ]
        diagnosticSettings: [
          {
            name: 'diag-to-law'
            workspaceResourceId: logAnalyticsWorkspaceId
          }
        ]
      }
    ]
    customData: loadTextContent('../../scripts/bootstrap-vm-init.sh')
  }
}

module bastionDeveloper 'br/public:avm/res/network/bastion-host:0.8.2' = {
  name: 'bas-${suffix}'
  params: {
    name: bastionName
    location: location
    tags: tags
    skuName: 'Developer'
    virtualNetworkResourceId: virtualNetworkId
  }
}

output bootstrapVmName string = bootstrapVm.outputs.name
output bootstrapVmResourceId string = bootstrapVm.outputs.resourceId
output bootstrapVmAdminUsername string = adminUsername
output bastionName string = bastionDeveloper.outputs.name
output bastionResourceId string = bastionDeveloper.outputs.resourceId
