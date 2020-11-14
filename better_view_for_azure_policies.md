---
description: By Jos Koelewijn (@Jawz_84)
---

# Create human readable default view for Azure Policies

Working with Azure policies in PowerShell can be annoying because the policy objects are by default not very human readable. 

```powershell
Get-AzPolicyDefinition -name 0473574d-2d43-4217-aefe-941fcdf7e684
```

```text
    Name               : 0473574d-2d43-4217-aefe-941fcdf7e684
    ResourceId         : /providers/Microsoft.bAuthorization/policyDefinitions/0473574d-2d43-4217-aefe-9
                         41fcdf7e684
    ResourceName       : 0473574d-2d43-4217-aefe-941fcdf7e684
    ResourceType       : Microsoft.Authorization/policyDefinitions
    SubscriptionId     : 
    Properties         : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolic
                         yDefinitionProperties
    PolicyDefinitionId : /providers/Microsoft.Authorization/policyDefinitions/0473574d-2d43-4217-aefe-9
                         41fcdf7e684
```

It's mainly guids and typenames that are displayed, not super helpful when you want to know which policy does what.
You can make your life easier by putting a few lines of code in your profile:

```powershell
using namespace Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy
 
# Update-TypeData is used to 'dig up' deeply nested properties and make them visible in the top-level object, 
# and create a default view for these two datatypes, to make policies easier to work with in PowerShell.
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "DisplayName" -Value { $this.Properties.DisplayName } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Description" -Value { $this.Properties.Description } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Deprecated" -Value { [bool]$this.Properties.Metadata.Deprecated } -Force
Update-TypeData -TypeName PsPolicyDefinition -MemberType ScriptProperty -MemberName "Category" -Value { $this.Properties.Metadata.Category } -Force
Update-TypeData -TypeName PsPolicyDefinition -DefaultDisplayPropertySet Name, DisplayName, Description -Force
 
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "DisplayName" -Value { $this.Properties.DisplayName } -Force
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "Description" -Value { $this.Properties.Description } -Force
Update-TypeData -TypeName PsPolicySetDefinition -MemberType ScriptProperty -MemberName "Deprecated" -Value { [bool]$this.Properties.Metadata.Deprecated } -Force
Update-TypeData -TypeName PsPolicySetDefinition -DefaultDisplayPropertySet Name, DisplayName, Description -Force
```

With these settings in place, we get this output:

```powershell
Get-AzPolicyDefinition -name 0473574d-2d43-4217-aefe-941fcdf7e684
```

```text
    Name                                 DisplayName                       Description
    ----                                 -----------                       -----------
    0473574d-2d43-4217-aefe-941fcdf7e684 Azure Cosmos DB allowed locations This policy enables you to …
```

A lot more readable, while all original data is still there! And notice you now also have an extra column 'Deprecated' available to you, that digs up that hidden property from within.

```powershell
Get-AzPolicyDefinition -name 0473574d-2d43-4217-aefe-941fcdf7e684 | select *
```

```text
    DisplayName        : Azure Cosmos DB allowed locations
    Description        : This policy enables you to restrict the locations your organization can specif
                         y when deploying Azure Cosmos DB resources. Use to enforce your geo-compliance
                          requirements.
    Deprecated         : False
    Category           : Cosmos DB
    Name               : 0473574d-2d43-4217-aefe-941fcdf7e684
    ResourceId         : /providers/Microsoft.Authorization/policyDefinitions/0473574d-2d43-4217-aefe-9
                         41fcdf7e684
    ResourceName       : 0473574d-2d43-4217-aefe-941fcdf7e684
    ResourceType       : Microsoft.Authorization/policyDefinitions
    SubscriptionId     : 
    Properties         : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolic
                         yDefinitionProperties
    PolicyDefinitionId : /providers/Microsoft.Authorization/policyDefinitions/0473574d-2d43-4217-aefe-9
                         41fcdf7e684
```

## Some remarks

tldr; this trick will only work for types for which there is no format data available.
 
PowerShell has a formatting system where it looks up how to format a certain type of object. 
This information can be found with `Get-FormatData`. 
A lot of it is built in in PowerShell. 
If you want to provide format data to PowerShell, you will need to write a `*.format.ps1xml` file, and import it with `Update-FormatData`. 
A bit tedious. 
 
I wanted something easier, so I used a trick:
When there is no format data available for a certain type, PowerShell looks for hints in the Type system. 
You can find that information with `Get-TypeData`. 
The `DefaultDisplayPropertySet` property can hold hints that PowerShell will use when there is no format data. 
That's what I have leveraged here, so I don't need to write a `*.format.ps1xml-file`.

