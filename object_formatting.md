---
description: 'By Jos Koelewijn ([@Jawz_84](https://www.twitter.com/Jawz_84))'
---

# Using the PowerShell formatting system to your advantage

## About Format and Type data

PowerShell has two main systems to determine what to show in the default view for a given type:

1. The Format system
2. The Type system

In that order; the Formatting system takes precedence over formatting info in the Type system.

Format data is completely centered around how a certain Type should be displayed. Type data is all about defining extra properties and methods, but also accomodates a `DefaultDisplayProperty` and `DefaultDisplayPropertySet` property that can be set.

For a lot of types, PowerShell has default Format and Type data built in. Many modules come with their Format and Type data as well. This information is applied _per Type_. Any time an object of a certain type is emitted to the console, formatting information is matched from the Format and Type system by Type name.

You can view currently loaded Format and Type data with `Get-FormatData` and `Get-TypeData`.

All related commands can be found with this line:

```text
Get-Command *data* -Module *powershell.utility |
    Select-Object -ExpandProperty Name |
    Where-Object { $_ -match "format|type" }
```

```text
Export-FormatData
Get-FormatData
Get-TypeData
Remove-TypeData
Update-FormatData
Update-TypeData
```

### Add or change Format data

Changing Format data can only be done by file import. `Update-FormatData` only accepts `ps1xml`-file data from a path. The file format is documented in the help of the command, I won't cover that here. The authoring experience [could be improved](https://github.com/PowerShell/PowerShell/issues/7749). An easy way to obtain a 'template' if you will, is by exporting the formatting data for an existing type, by using `Export-FormatData -Typename 'TypeIWantToExport'`. Imported Format data will be lost at the end of the session.

### Add or change Type data

Type data can be changed by file import as well, but less known is the fact you can also use `Update-TypeData` with parameters. For example to add a Property to a Type, you can Use it with `-Force` when you need to overwrite existing data. Imported Type data will also be lost at the end of the session, or you can choose to remove Type data from the session with `Remove-TypeData`.

## How to use this to our advantage

### Types with Format data loaded \(the hard way\)

Types for which Format data is already present in the session, like `[System.TimeSpan]`, we need to export that data to a file, change it, and import it again.

This is the default view for `New-TimeSpan` \(Output Type is `[System.TimeSpan]`\):

```text
New-TimeSpan -Seconds 100
```

```text
    Days              : 0
    Hours             : 0
    Minutes           : 1
    Seconds           : 40
    Milliseconds      : 0
    Ticks             : 1000000000
    TotalDays         : 0,00115740740740741
    TotalHours        : 0,0277777777777778
    TotalMinutes      : 1,66666666666667
    TotalSeconds      : 100
    TotalMilliseconds : 100000
```

First, we get the Format data:

```text
$file = "$env:TEMP\timeSpan.format.ps1xml"
Get-FormatData -TypeName System.TimeSpan | 
    Export-FormatData -IncludeScriptBlock -Path $file
```

We can now go about various ways to view this `ps1xml`-file. You can edit it with your favourite code editor or use PowerShell to do some reconnaissance:

```text
$timeSpanFormatData = [xml](Get-Content $file)
$timeSpanFormatData.Configuration.ViewDefinitions.View | 
    Select-Object Name, ListControl, TableControl, WideControl
```

```text
    Name            ListControl TableControl WideControl
    ----            ----------- ------------ -----------
    System.TimeSpan ListControl              
    System.TimeSpan             TableControl 
    System.TimeSpan                          WideControl
```

We see there are three views available, one for List, one for Table and one for Wide. These will be used by `Format-List`, `Format-Table` and `Format-Wide` respectively. When none of these is used, PowerShell will use the List view or Table view, depending on the amount of properties to display. Four or less properties will result in Table view, more than four properties in List view.

Let's say we want to edit the List view for `[System.TimeSpan]`. That's this part of the file:

```markup
    ..
    <View>
      <Name>System.TimeSpan</Name>
      <ViewSelectedBy>
        <TypeName>System.TimeSpan</TypeName>
      </ViewSelectedBy>
      <ListControl>
        <ListEntries>
          <ListEntry>
            <ListItems>
              <ListItem>
                <PropertyName>Days</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>Hours</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>Minutes</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>Seconds</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>Milliseconds</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>Ticks</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>TotalDays</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>TotalHours</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>TotalMinutes</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>TotalSeconds</PropertyName>
              </ListItem>
              <ListItem>
                <PropertyName>TotalMilliseconds</PropertyName>
              </ListItem>
            </ListItems>
          </ListEntry>
        </ListEntries>
      </ListControl>
    </View>
    ..
```

We can see there are a lot of ListItems defined. Let's say we want to remove half of them, keeping only `Days`, `Hours`, `Minutes` and `Seconds`. Remove the other blocks of xml code, save the file, and import it back to the session with this:

```text
code $file --wait
Update-FormatData -PrependPath $file
```

Now, `New-TimeSpan` should have a condensed default view. Let's test it out:

```text
New-TimeSpan -Seconds 100
```

```text
    Days    : 0
    Hours   : 0
    Minutes : 1
    Seconds : 40
```

At the time of writing, there is [an open issue](https://github.com/PowerShell/PowerShell/issues/7845) to expand `Update-FormatData` with parameters to be more like `Update-TypeData`. For now, there is no other way. This is the way.

### Types without Format data loaded \(the easy way\)

Types for wich there is no preexisting Format data in the current session are the easiest because there we can directly set the default view by using the `DefaultDisplayPropertySet` parameter of `Update-TypeData`.

An example with a `PSCustomObject`:

```text
$myObject = [pscustomobject]@{
    PSTypeName='MyType'
    A='a'
    B='b'
    C='c'
}
$myObject
```

```text
    A B C
    - - -
    a b c
```

A very simple object with only three properties, that we give a Type name of 'MyType', by specifying PSTypeName in the PSCustomObject.

Let's set the default display property set, to change which properties are shown by default:

```text
Update-TypeData -TypeName 'MyType' -DefaultDisplayPropertySet A, B
$myObject
```

```text
    A B
    - -
    a b
```

Even though there is a property C, it is now hidden.

> Note: When you want to overwrite existing Type data, you need to use the `-Force` switch with `Update-TypeData`, or it will throw an error.

You can check if your session currently has Format data for your target Type like this:

```text
Get-FormatData -TypeName 'MyType'
```

If it does not return anything, there is no Format data for `MyType`.

## Real world applications

You can define a default set of properties to show for objects you created, right there in the code where the object is defined. Be it a PowerShell class, a C\# class, or a PsCustomObject with the PSTypeName trick.

```text
class MyClass {
    [bool]$IsThingPresent
    [string]$Foo
    [string]$Bar
    [string]$Baz
    [string]$FooBar
}
Update-TypeData -TypeName MyClass -DefaultDisplayPropertySet Foo, Bar, IsThingPresent
[MyClass]@{
    IsThingPresent = $true
    Foo = 'foo'
    Bar = 'bar'
    Baz = 'baz'
}
```

```text
    Foo Bar IsThingPresent
    --- --- --------------
    foo bar           True
```

When the object has nested objects, you can do fun things with them, like digging up that nested data, and showing them at the top level. See [this blog post about Azure Policies](https://joskw.gitbook.io/blog/azure-view) for an example of that.

The two things I like most about this, is that it does not require you to author a lengthy XML file, and your formatting information can sit right next to your Type definition.

I hope you found this useful. Please feel free to reach out to me if you have questions. You can [ping me on Twitter](https://www.twitter.com/Jawz_84), or drop me a message on the PowerShell Discord server.

