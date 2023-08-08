
@description('Required. Name of the Key Vault. Must be globally unique.')
@maxLength(24)
param keyVaultName string = 'Test-KeyVault-1'

@description('Key Vault Secret name which contains local administrator name')
@allowed([
  'vmAdmin'
  'vmAdmin1'
])
param vmAdmin string

@description('Key Vault Secret name which contains local administrator password')
@secure()
@allowed([
  'vmAdminPassword'
  'vmAdminPassword1'
])
param vmAdminPassword string

@description('Select the resource group that the virtual network belongs to')
@allowed([
  'Test-RG'
  'rg-ccs-test-usva-mgmt'
])
param vNetResourceGroup string = 'Test-RG'

@description('Select the Virtual Network the VM should be deployed to')
@allowed([
  'Test-VNet-1'
  'Test-VNet-2'
])
param vNetName string = 'Test-VNet-1'

@description('Select the subnet the VM should be deployed to')
@allowed([
  'Subnet1'
  'Subnet2'
  'Subnet3'
])
param subnetName string = 'Subnet1'

@description('Name of the virtual machine to be created')
@maxLength(15)
param virtualMachineNamePrefix string = 'vm-test-0'

@description('Virtual Machine Name Suffix')
@maxLength(15)
param virtualMachineNameSuffix string

@description('Select the virtual machine size')
@allowed([
  'Standard_DS1_v2'
  'Standard_D2s_v3'
  'Standard_DS2_v2'
  'Standard_D4s_v3'
  'Standard_DS3_v2'
  'Standard_D8s_v3'
])
param vmSize string = 'Standard_DS2_v2'

@description('''
Provide the size of the data disk(s) in GB. Use comma seperator for more than one disks.
[{"diskSizeGB":"32"},{"diskSizeGB":"64"}]
''')
param dataDisks array = [
  {
    diskSizeGB: '32'
  }
  {
    diskSizeGB: '64'
  }
]

@description('Required. The chosen OS type.')
@allowed([
  'Windows'
  'Linux'
])
param osType string

@description('Optional. Specifies that the image or disk that is being used was licensed on-premises. This element is only used for images that contain the Windows Server operating system.')
@allowed([
  'Windows_Client'
  'Windows_Server'
  'RHEL_BYOS'
  'SLES_BYOS'
  ''
])
param licenseType string = ''

@description('Select the resource group that the virtual network belongs to')
@allowed([
  'Server2012R2'
  'Server2016'
  'Server2019'
  'Server2022'
  'UbuntuServer1604LTS'
  'UbuntuServer1804LTS'
  'UbuntuServer1904'
  'RedHat85Gen2'
  'RedHat86Gen2'
  'RedHat90Gen2'
])
param operatingSystem string = 'Server2019'

@description('Operating Systems Values')
var operatingSystemValues = {
  Server2012R2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-r2-datacenter-gensecond'
  }
  Server2016: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-datacenter-gensecond'
  }
  Server2019: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-datacenter-gensecond'
  }
  Server2022: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
  }
  UbuntuServer1604LTS: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16_04-lts-gen2'
  }
  UbuntuServer1804LTS: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
  }
  UbuntuServer1904: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '19_04-gen2'
  }
  RedHat85Gen2: {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '85-gen2'
  }
  RedHat86Gen2: {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '86-gen2'
  }
  RedHat90Gen2: {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '90-gen2'
  }
}

@description('Optional. Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings.')
param securityType string = 'TrustedLaunch'

@description('Optional. Specifies the time zone of the virtual machine. e.g. \'Pacific Standard Time\'. Possible values can be `TimeZoneInfo.id` value from time zones returned by `TimeZoneInfo.GetSystemTimeZones`.')
param timeZone string = 'Eastern Standard Time'

@description('Example: {"Environment":"demo","Owner":"IT"}')
param tags object = {
  Application: 'DemoApp'
  Application_Function: 'Sales'
  Class_of_Service: 'Prod'
  Organization: 'IT'
  Ticket_ID: '123456'
}

@description('Resource group where the Recovery Services Vault is located. This can be different than resource group of the Virtual Machines.')
param recoveryServicesVaultRgName string = 'Test-RG'

@description('Name of the Recovery Services Vault')
param recoveryServicesVaultName string = 'Test-RSV'

@description('Name of the Backup policy to be used to backup VMs. Backup Policy defines the schedule of the backup and how long to retain backup copies. By default every vault comes with a \'DefaultPolicy\' which canbe used here.')
param backupPolicyName string = 'EnhancedPolicy'

// 1. Retrieve an exisiting Key Vault (From Management Subscription)
resource akv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  //scope: resourceGroup(mgmtsubid, siemRgName)
}

// 2. Create Virtual Machines
module vmDeploy 'modules/compute/virtualMachines/deploy.bicep' = {
  name: 'vmDeploy-${virtualMachineNamePrefix}${virtualMachineNameSuffix}'
  //scope: resourceGroup(subscriptionId, wlRgName)
  params: {
    name: '${virtualMachineNamePrefix}${virtualMachineNameSuffix}'
    location: resourceGroup().location
    tags: tags
    adminUsername: akv.getSecret(vmAdmin)
    adminPassword: akv.getSecret(vmAdminPassword)
    vmComputerNamesTransformation: 'lowercase'
    osType: osType
    vmSize: vmSize
    licenseType: licenseType
    timeZone: timeZone
    securityType: securityType
    imageReference: {
      publisher: operatingSystemValues[operatingSystem].publisher
      offer: operatingSystemValues[operatingSystem].offer
      sku: operatingSystemValues[operatingSystem].sku
      version: 'latest'
    }
    osDisk: {
      createOption: 'FromImage'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
      caching: 'ReadWrite'
    }
    dataDisks: [for (dataDisk, index) in dataDisks: {
      diskSizeGB: dataDisk.diskSizeGB
      caching: 'ReadOnly'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }]
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        ipConfigurations: [
          {
            applicationSecurityGroups: []
            loadBalancerBackendAddressPools: []
            name: 'ipconfig01'
            subnetResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${subnetName}'
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]

  }
}


// 3. Configure Virtual Machine Backup
module vmBackup 'modules/recoveryServices/vaults/vmBackup/deploy.bicep' = {
  name: 'vmBackup-${virtualMachineNamePrefix}${virtualMachineNameSuffix}'
  //scope: resourceGroup(subscriptionId, vaultRgName)
  dependsOn: [
    vmDeploy
  ]
  params: {
    location: resourceGroup().location
    subscriptionId: subscription().subscriptionId
    vmRgName: vNetResourceGroup
    vmName: '${virtualMachineNamePrefix}${virtualMachineNameSuffix}'    
    vaultRgName: recoveryServicesVaultRgName
    vaultName: recoveryServicesVaultName
    backupPolicyName: backupPolicyName
  }
}

















































/*
@description('Output - Array of Virtual Machine Resoruce IDs')
output vmResourceIDs array = [for (virtualMachine, i) in virtualMachines: {
  vmResourceId: lzVm[i].outputs.resourceId
}]



targetScope = 'managementGroup'

@description('Location for the deployments and the resources')
@allowed([
  'usgovvirginia'
  'usgovarizona'
  'usgovtexas'
])
param location string = 'usgovvirginia'

@description('Optional. Specifies whether secure boot should be enabled on the virtual machine. This parameter is part of the UefiSettings. SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param secureBootEnabled bool = false

@description('Optional. Specifies whether vTPM should be enabled on the virtual machine. This parameter is part of the UefiSettings.  SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param vTpmEnabled bool = false



@description('Optional. The configuration for the [Key Vault] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionKeyVaultConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Custom Script] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionCustomScriptConfig object = {
  enabled: false
  fileData: []
}

@description('Optional. The array of Virtual Machines.')
param virtualMachines array

@description('Required. Subscription ID of Management Subscription.')
param mgmtsubid string

@description('Required. SIEM Resource Group Name.')
param siemRgName string = 'rg-${platformProjOwner}-${platformOpScope}-${region}-siem'


@description('Required. "projowner" parameter used for Platform.')
param platformProjOwner string

@description('Required. "opscope" parameter used for Platform.')
param platformOpScope string

@description('Required. Region (region) parameter.')
@allowed([
  'usva'
  'ustx'
  'usaz'
])
param region string

@description('Required. Administrator username.')
@secure()
param adminUsername string

@description('Optional. When specifying a Windows Virtual Machine, this value should be passed.')
@secure()
param adminPassword string = ''

@description('Optional. The name of the virtual machine to be created. You should use a unique prefix to reduce name collisions in Active Directory. If no value is provided, a 10 character long unique string will be generated based on the Resource Group\'s name.')
param name string

@description('Optional. Specifies that the image or disk that is being used was licensed on-premises. This element is only used for images that contain the Windows Server operating system.')
@allowed([
  'Windows_Client'
  'Windows_Server'
  'RHEL_BYOS'
  'SLES_BYOS'
  ''
])
param licenseType string = ''

@description('Optional. Specifies the data disks. For security reasons, it is recommended to specify DiskEncryptionSet into the dataDisk object. Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
param dataDisks array = []



@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the monitoring log analytics workspace. Must be set when extensionMonitoringAgentConfig is set to true.')
param monitoringWorkspaceId string = ''


@description('Required. The chosen OS type.')
@allowed([
  'Windows'
  'Linux'
])
param osType string

@description('Virtual Machine Size')
param virtualMachineSize string = 'Standard_DS2_v2'

@description('Operating System of the Server')
@allowed([
  'Server2012R2'
  'Server2016'
  'Server2019'
  'Server2022'
  'UbuntuServer1604LTS'
  'UbuntuServer1804LTS'
  'UbuntuServer1904'
  'RedHat85Gen2'
  'RedHat86Gen2'
  'RedHat90Gen2'
])
param operatingSystem string = 'Server2019'

@description('Optional. If set to 1, 2 or 3, the availability zone for all VMs is hardcoded to that value. If zero, then availability zones is not used. Cannot be used in combination with availability set nor scale set.')
@allowed([
  0
  1
  2
  3
])
param availabilityZone int = 0

@description('Availability Set Name where the VM will be placed')
param availabilitySetName string = 'MyAvailabilitySet'

@description('Optional. Resource ID of an availability set. Cannot be used in combination with availability zone nor scale set.')
param availabilitySetResourceId string = ''

var availabilitySetPlatformFaultDomainCount = 2
var availabilitySetPlatformUpdateDomainCount = 5

resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: availabilitySetPlatformFaultDomainCount
    platformUpdateDomainCount: availabilitySetPlatformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}


    /*
    diagnosticWorkspaceId: diagnosticWorkspaceId
    extensionMonitoringAgentConfig: {
      enabled: false
    }
    monitoringWorkspaceId: monitoringWorkspaceId
    extensionDependencyAgentConfig: {
      enabled: false
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: false
    }

    extensionKeyVaultConfig: {
      enabled: extensionKeyVaultConfig.enabled
      keyVaultSecretId: [
        '${akv.properties.vaultUri}secrets/${extensionKeyVaultConfig.keyVaultRootCertSecretName}'
      ]
    }
    extensionCustomScriptConfig: extensionCustomScriptConfig

    extensionAntiMalwareConfig: osType == 'Windows' ? {
      enabled: true
      settings: {
        AntimalwareEnabled: 'true'
        Exclusions: {
          Extensions: '.ext1;.ext2'
          Paths: 'c:\\excluded-path-1;c:\\excluded-path-2'
          Processes: 'excludedproc1.exe;excludedproc2.exe'
        }
        RealtimeProtectionEnabled: 'true'
        ScheduledScanSettings: {
          day: '7'
          isEnabled: 'true'
          scanType: 'Quick'
          time: '120'
        }
      }
    } : {
      enabled: false
    }
  
*/
