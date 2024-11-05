param (
    [string]$packageFiles,           # Path to the YAML file
    [string]$destinationRootFolder   # Root destination folder
)

# Import-Module for YAML parsing (only needed if you use YamlDotNet)
# Install-Module -Name powershell-yaml -Force -Scope CurrentUser
# Import-Module powershell-yaml

# Function to expand environment variables in a path
function Expand-PathWithEnvVars {
    param (
        [string]$path
    )
    return [Environment]::ExpandEnvironmentVariables($path)
}

# Function to log information messages
function LogInformation {
    param (
        [string]$message
    )
    Write-Host $message
}

# Function to copy an entire folder to the destination
function CopyFolder {
    param (
        [string]$sourceFolder,
        [string]$fullDestinationFolder
    )

    # Create a subfolder in the destination based on the source folder's name
    $destinationSubFolder = Join-Path -Path $fullDestinationFolder -ChildPath (Split-Path -Leaf $sourceFolder)
    Copy-Item -Path $sourceFolder -Destination $destinationSubFolder -Recurse -Force
    LogInformation "Copied directory $sourceFolder to $destinationSubFolder"
}

# Function to copy files to the destination
function CopyFiles {
    param (
        [string]$sourcePath,
        [string]$fullDestinationFolder
    )

    # Retrieve files that match the path, including wildcards
    $sourceFiles = Get-ChildItem -Path $sourcePath -File -ErrorAction SilentlyContinue

    if ($null -eq $sourceFiles) {
        LogInformation "No files matched for path: $sourcePath"
        return
    }

    # Copy each file to the destination folder
    foreach ($file in $sourceFiles) {
        $destinationFilePath = Join-Path -Path $fullDestinationFolder -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
        LogInformation "Copied file $($file.FullName) to $destinationFilePath"
    }
}

# Function to process each source path and copy to the destination
function ProcessSourcePath {
    param (
        [string]$expandedSourcePath,
        [string]$fullDestinationFolder
    )

    if (Test-Path -Path $expandedSourcePath -PathType Container) {
        # If expandedSourcePath is a directory, call CopyFolder
        CopyFolder -sourceFolder $expandedSourcePath -fullDestinationFolder $fullDestinationFolder
    } else {
        # Otherwise, treat it as a file or wildcard path and call CopyFiles
        CopyFiles -sourcePath $expandedSourcePath -fullDestinationFolder $fullDestinationFolder
    }
}

# Function to process each destination folder and its associated file paths
function ProcessDestinationFolder {
    param (
        [string]$destinationFolder,
        [array]$sourcePaths
    )

    # Combine the root destination folder with the YAML-specified folder
    $fullDestinationFolder = Join-Path -Path $destinationRootFolder -ChildPath $destinationFolder

    # Ensure destination folder exists
    if (!(Test-Path -Path $fullDestinationFolder)) {
        New-Item -ItemType Directory -Path $fullDestinationFolder -Force
    }

    foreach ($sourcePath in $sourcePaths) {
        # Expand environment variables in the source path
        $expandedSourcePath = Expand-PathWithEnvVars -path $sourcePath
        ProcessSourcePath -expandedSourcePath $expandedSourcePath -fullDestinationFolder $fullDestinationFolder
    }
}

# Load YAML file and parse it
$yamlContent = Get-Content -Path $packageFiles -Raw
$parsedYaml = ConvertFrom-Yaml -Yaml $yamlContent

# Process each destination folder in the YAML file
foreach ($destinationFolder in $parsedYaml.Keys) {
    $sourcePaths = $parsedYaml[$destinationFolder]
    ProcessDestinationFolder -destinationFolder $destinationFolder -sourcePaths $sourcePaths
}
