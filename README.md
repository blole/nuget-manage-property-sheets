# nuget-manage-property-sheets
PowerShell functions to add/remove property sheets in Visual Studio projects

# Example nuget application
If you want to install a regular property sheet `tools\sheet.props` with your nuget package, add this to your corresponding files:

###### x-package.nuspec
```xml
<dependencies>
	<dependency id="manage-property-sheets" version="[1,2)" />
</dependencies>
```

###### install.ps1
```ps1
param($installPath, $toolsPath, $package, $project)
$pspkg = $(ls "$installPath\..\manage-property-sheets*")[-1]
. "$pspkg\tools\manage-property-sheets.ps1"

Add-Property-Sheet $project "$toolsPath\sheet.props"
```

###### uninstall.ps1
```ps1
param($installPath, $toolsPath, $package, $project)
$pspkg = $(ls "$installPath\..\manage-property-sheets*")[-1]
. "$pspkg\tools\manage-property-sheets.ps1"

Remove-Property-Sheet $project "$toolsPath\sheet.props"
```
