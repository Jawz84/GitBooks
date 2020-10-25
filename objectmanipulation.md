---
description: By Jos Koelewijn (@Jawz_84)
---

# Make objects show and behave themselves like you want them to

PowerShell is good with objects, that is well known. 
A lesser known fact is that you can dynamically define what you want an object to look like in your default output.
What's also less known is that you can extend existing objects. 

Let's take a closer look at these features and how to use them to our advantage.

## Dynamically set the Default Display Property Set

What does that mean?
Let's look at an example.

When you run `Get-Service -Name fax`, you get this:

```
Status   Name               DisplayName
------   ----               -----------
Stopped  Fax                fax
```

Only three properties are displayed. 
But there are more properties:

```powershell
Get-Service -Name fax | Get-Member -MemberType Properties


   TypeName: System.Service.ServiceController#StartupType

Name                MemberType    Definition
----                ----------    ----------
Name                AliasProperty Name = ServiceName
RequiredServices    AliasProperty RequiredServices = ServicesDependedOn
BinaryPathName      Property      System.String {get;set;}
CanPauseAndContinue Property      bool CanPauseAndContinue {get;}
CanShutdown         Property      bool CanShutdown {get;}
CanStop             Property      bool CanStop {get;}
Container           Property      System.ComponentModel.IContainer Container {get;}
DelayedAutoStart    Property      System.Boolean {get;set;}
DependentServices   Property      System.ServiceProcess.ServiceController[] DependentServices {get;}
Description         Property      System.String {get;set;}
DisplayName         Property      string DisplayName {get;set;}
MachineName         Property      string MachineName {get;set;}
ServiceHandle       Property      System.Runtime.InteropServices.SafeHandle ServiceHandle {get;}
ServiceName         Property      string ServiceName {get;set;}
ServicesDependedOn  Property      System.ServiceProcess.ServiceController[] ServicesDependedOn {get;}
ServiceType         Property      System.ServiceProcess.ServiceType ServiceType {get;}
Site                Property      System.ComponentModel.ISite Site {get;set;}
StartType           Property      System.ServiceProcess.ServiceStartMode StartType {get;}
StartupType         Property      Microsoft.PowerShell.Commands.ServiceStartupType {get;set;}
Status              Property      System.ServiceProcess.ServiceControllerStatus Status {get;}
UserName            Property      System.String {get;set;}
```

But most of these properties are hidden by default, to provide end users with nice concise views.
How does PowerShell do this?
By using metadata per type, type data.
For a lot of types, PowerShell has metadata on which properties to display by default. 
We can look at this by using `Get-TypeData`. 
Remember the type name mentioned in the output of `Get-Member` above was with `System.Service.ServiceController#StartupType`?
Let's look up it's type data:

```powershell
Get-TypeData -TypeName system*servicecontroller* | Select-Object TypeName, {$_.DefaultDisplayPropertySet.ReferencedProperties}

TypeName                                $_.defaultdisplaypropertyset.referencedproperties
--------                                -------------------------------------------------
System.ServiceProcess.ServiceController {Status, Name, DisplayName}
```




```powershell
(Get-TypeData -TypeName System.ServiceProcess.ServiceController).DefaultDisplayPropertySet
```


```powershell
#region PSCustomObject
# You can do this with your own custom objects too:

$myObject = [PSCustomObject]@{
    PSTypeName = 'My.Object'  # This is how you can give your custom object an identifier for use with Update-TypeData
    Name       = 'Jos'
    Language   = 'Powershell'
    Country    = 'Netherlands'
    TheAnswer  = 42
}

Update-TypeData -TypeName my.object -DefaultDisplayPropertySet Language, Country -Force

# $myObject now has a default display mode, a view
$myObject | Out-Default

# but it holds more data under the hood. 
$myObject | Select-Object * | Out-Default

$mydumbobject = [PSCustomObject]@{
    Name      = 'Jos'
    Language  = 'Powershell'
    Country   = 'Netherlands'    
    TheAnswer = 42
}
$mydumbobject | Out-Default

$mydumbobject | Select-Object * | Out-Default

#endregion 

#region Custom Class

class MyClassObject {
    [bool] $IsCool
    [string] $Name
    [string] $Language
}

Update-TypeData -TypeName MyClassObject -DefaultDisplayPropertySet Language, IsCool -Force

$instance = [MyClassObject]@{
    IsCool   = $true
    Name     = 'Instance1'
    Language = 'PowerShell'
}
$instance | Out-Default

$instance | Select-Object * | Out-Default

```


## custom json view

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Location where all resources will be created."
            }
        },
        "virtualHubName": {
            "type": "string"
        },
        "virtualWanName": {
            "type": "string"
        },
        "azureFirewallName": {
            "type": "string"
        },
        "addressPrefix": {
            "type": "string"
        },
        "logAnalyticsWorkspaceResourceGroup": {
            "type": "string"
        },
        "logAnalyticsWorkspaceName": {
            "type": "string"
        }
    },
    "resources": [
        {
            "type": "Microsoft.Network/virtualHubs",
            "apiVersion": "2020-04-01",
            "name": "[parameters('virtualHubName')]",
            "location": "[parameters('location')]",
            "tags": {},
            "properties": {
                "addressPrefix": "[parameters('addressPrefix')]",
                "virtualWan": {
                    "id": "[resourceId('Microsoft.Network/virtualWans', parameters('virtualWanName'))]"
                },
                "azureFirewall": {
                    "id": "[resourceId('Microsoft.Network/azureFirewalls', parameters('azureFirewallName'))]"
                }
            },
            "resources": [
                {
                    "type": "providers/locks",
                    "name": "[toLower(concat('/Microsoft.Authorization/', parameters('virtualHubName'), '-lock'))]",
                    "apiVersion": "2017-04-01",
                    "dependsOn": [
                        "[parameters('virtualHubName')]"
                    ],
                    "properties": {
                        "level": "CannotDelete",
                        "notes": "Do not delete!"
                    }
                }
            ]
        },
        {
            "type": "Microsoft.Network/azureFirewalls",
            "apiVersion": "2020-05-01",
            "name": "[parameters('azureFirewallName')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualHubs', parameters('virtualHubName'))]"
            ],
            "properties": {
                "sku": {
                    "name": "AZFW_Hub",
                    "tier": "Standard"
                },
                "hubIPAddresses": {
                    "publicIPs": {
                        "count": 1
                    }
                },
                "virtualHub": {
                    "id": "[resourceId('Microsoft.Network/virtualHubs', parameters('virtualHubName'))]"
                }
            },
            "resources": [
                {
                    "type": "providers/diagnosticSettings",
                    "name": "Microsoft.Insights/service",
                    "apiVersion": "2016-09-01",
                    "dependsOn": [
                        "[parameters('azureFirewallName')]"
                    ],
                    "properties": {
                        "workspaceId": "[resourceId(parameters('logAnalyticsWorkspaceResourceGroup'), 'Microsoft.OperationalInsights/workspaces/', parameters('logAnalyticsWorkspaceName'))]",
                        "logs": [
                            {
                                "category": "AzureFirewallApplicationRule",
                                "enabled": true
                            },
                            {
                                "category": "AzureFirewallNetworkRule",
                                "enabled": true
                            }
                        ],
                        "metrics": [
                            {
                                "category": "AllMetrics",
                                "enabled": true,
                                "retentionPolicy": {
                                    "enabled": false,
                                    "days": 0
                                }
                            }
                        ]
                    }
                },
                {
                    "type": "providers/locks",
                    "name": "[toLower(concat('/Microsoft.Authorization/', parameters('azureFirewallName'), '-lock'))]",
                    "apiVersion": "2017-04-01",
                    "dependsOn": [
                        "[parameters('azureFirewallName')]"
                    ],
                    "properties": {
                        "level": "CannotDelete",
                        "notes": "Do not delete!"
                    }
                }
            ]
        }
    ]
}
```

```powershell
$hashtable = Get-Content ~\Desktop\arm.json | ConvertFrom-Json -AsHashtable
$hashtable.Add('PSTypeName', 'ARMDeploymentTemplate')
$object = [PSCustomObject]$hashtable


Update-TypeData -TypeName ARMDeploymentTemplate -MemberType ScriptProperty -MemberName "ResourceTypes" -value {$this.resources.type} -Force
Update-TypeData -TypeName ARMDeploymentTemplate -MemberType ScriptProperty -MemberName "SubresourceTypes" -value {$this.resources.resources.type} -Force
Update-TypeData -TypeName ARMDeploymentTemplate -MemberType ScriptProperty -MemberName "ResourceNames" -value {$this.resources.name} -Force
Update-TypeData -TypeName ARMDeploymentTemplate -MemberType ScriptProperty -MemberName "SubresourceNames" -value {$this.resources.resources.name} -Force
Update-TypeData -TypeName ARMDeploymentTemplate -DefaultDisplayPropertySet ResourceTypes, ResourceNames, SubresourceTypes, SubresourceNames -Force
$object
#endregion custom json view
```




```powershell
#requires -Version 7.0
using namespace Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy

# Update-TypeData is used to 'dig up' deeply nested properties and make them visible in the top-level object, 
# and create a default view for these two datatypes, to make policies easier to work with in PowerShell.
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "DisplayName" -Value { $this.Properties.DisplayName } -Force
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "Description" -Value { $this.Properties.Description } -Force
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "Deprecated" -Value { [bool]$this.Properties.Metadata.Deprecated } -Force
Update-TypeData -TypeName PsPolicySetDefinition -DefaultDisplayPropertySet Name, DisplayName, Description -Force

Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "DisplayName" -Value { $this.Properties.DisplayName } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Description" -Value { $this.Properties.Description } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Deprecated" -Value { [bool]$this.Properties.Metadata.Deprecated } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Category" -Value { $this.Properties.Metadata.Category } -Force
Update-TypeData -TypeName PsPolicyDefinition -DefaultDisplayPropertySet InitiativeName, Name, DisplayName, Description -Force

function Get-APPoliciesInInitiative {
    <#
    .SYNOPSIS
        Peel Policy Definitions from Policy Set Definitions
    .DESCRIPTION
        Peel Policy Definitions from Policy Set Definitions and enrich the output with the name of the originating Policy Set Definition.
    .EXAMPLE
        PS C:\> Get-AzPolicySetDefinition | Get-APPoliciesInInitiative
        List all policies in all Policy Set Definitions (aka Initiatives).
    #>
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [PsPolicySetDefinitionProperties]
        $Properties,
        
        [parameter(ValueFromPipelineByPropertyName)]
        [String]
        $DisplayName
    )

    process {
        $Properties.PolicyDefinitions 
        | Select-Object @{ Label = "Id"; Expression = { $_.PolicyDefinitionId } } # create an alias 'Id' for 'PolicyDefinitionId' so the Get-AzPolicyDefinition command understands it.
        | Get-AzPolicyDefinition 
        | Add-Member -TypeName NoteProperty -NotePropertyName "InitiativeName" -NotePropertyValue $DisplayName -PassThru
    }
}


break
# Usage examples

# Get all current (non-deprecated) built in policy set definitions, sorted
Get-AzPolicySetDefinition -Builtin | Where-Object { -not $_.Deprecated } | Sort-Object DisplayName

# Get all deprecated policies in all custom policy set definitions
Get-AzPolicySetDefinition -Custom | Get-APPoliciesInInitiative | Where-Object Deprecated | Out-Default

```

