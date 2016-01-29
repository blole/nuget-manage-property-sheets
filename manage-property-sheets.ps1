function Relative-Path ([string]$from, [string]$to)
{
	Push-Location
	Set-Location "$from"
	Write-Output $(Resolve-Path -Relative "$to")
	Pop-Location
}

# from http://stackoverflow.com/questions/12292577/how-can-i-reload-a-visual-studio-project-thru-a-nuget-powershell-script
function Select-Project ([string]$projectName)
{
	#following GUID = Constants.vsWindowKindSolutionExplorer
	#magic 1 = vsUISelectionType.vsUISelectionTypeSelect
	$shortpath = $dte.Solution.Properties.Item("Name").Value + "\" + $projectName
	$dte.Windows.Item("{3AE79031-E1BC-11D0-8F78-00A0C9110057}").Activate()
	$dte.ActiveWindow.Object.GetItem($shortpath).Select(1)
}

# The goal is to add something like this to the projects' .vcxproj:
# <ImportGroup Condition="'$(Configuration)|$(Platform)'=='Release|Win32'" Label="PropertySheets">
#+  <Import Project="..\packages\package.x.y.z\tools\sheet.props" Condition="exists('..\packages\package.x.y.z\tools\sheet.props')" />
#   ...
# </ImportGroup>
function Add-Property-Sheet ($project, [string]$propertySheetPath, [bool]$prepend=$False)
{
	$projectName = $project.Name
	$projectFullName = $project.FullName
	$projectDir = $project.Properties.Item("ProjectDirectory").Value
	$propertySheetRelPath = Relative-Path $projectDir $propertySheetPath
	
	Select-Project $projectName
	$dte.ExecuteCommand("Project.UnloadProject")
	$projectMSBuild = [Microsoft.Build.Construction.ProjectRootElement]::Open($projectFullName)
	
	foreach ($propertySheetGroup in $projectMSBuild.ImportGroups | where {$_.Label -eq "PropertySheets"})
	{
		$import = $projectMSBuild.CreateImportElement($propertySheetRelPath);
		$import.Condition = "exists('"+$propertySheetRelPath+"')"
		if ($prepend)
		{
			$propertySheetGroup.PrependChild($import)
		}
		else
		{
			$propertySheetGroup.AppendChild($import)
		}
	}
	
	$projectMSBuild.Save()
	Select-Project $projectName
	$dte.ExecuteCommand("Project.ReloadProject")
}

# Unloading and reloading projects does not seem to work in uninstall scripts:
#   "uninstall-package : Cannot access a disposed object."
# So we'll just save the project and trigger a reload.
function Remove-Property-Sheet ($project, [string]$propertySheetPath)
{
	$projectDir = $project.Properties.Item("ProjectDirectory").Value
	$propertySheetRelPath = Relative-Path $projectDir $propertySheetPath
	
	$project.Save()
	$projectMSBuild = [Microsoft.Build.Construction.ProjectRootElement]::Open($project.FullName)
	
	foreach ($import in $projectMSBuild.Imports | where {$_.Project -eq $propertySheetRelPath})
	{
		$import.Parent.RemoveChild($import)
	}
	
	$projectMSBuild.Save()
	$(get-item $project.FullName).lastwritetime=get-date #trigger reload
}
