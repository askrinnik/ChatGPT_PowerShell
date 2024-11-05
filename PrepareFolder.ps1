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

# Load YAML file and parse it
$yamlContent = Get-Content -Path $packageFiles -Raw

# Parse YAML to Hashtable
$parsedYaml = ConvertFrom-Yaml -Yaml $yamlContent

# Process each destination and its associated file paths
foreach ($destinationFolder in $parsedYaml.Keys) {
    # Combine the root destination folder with the YAML-specified folder
    $fullDestinationFolder = Join-Path -Path $destinationRootFolder -ChildPath $destinationFolder

    # Ensure destination folder exists
    if (!(Test-Path -Path $fullDestinationFolder)) {
        New-Item -ItemType Directory -Path $fullDestinationFolder -Force
    }

    # Get each source path from YAML
    $sourcePaths = $parsedYaml[$destinationFolder]

    foreach ($sourcePath in $sourcePaths) {
        # Expand environment variables in the source path
        $expandedSourcePath = Expand-PathWithEnvVars -path $sourcePath

        if (Test-Path -Path $expandedSourcePath -PathType Container) {
            # If expandedSourcePath is a directory, copy entire directory to destination
            $destinationSubFolder = Join-Path -Path $fullDestinationFolder -ChildPath (Split-Path -Leaf $expandedSourcePath)
            Copy-Item -Path $expandedSourcePath -Destination $destinationSubFolder -Recurse -Force
            Write-Host "Copied directory $expandedSourcePath to $destinationSubFolder"
        } else {
            # Handle wildcards or specific files in the expanded source path
            $sourceFiles = Get-ChildItem -Path $expandedSourcePath -File -ErrorAction SilentlyContinue

            if ($null -eq $sourceFiles) {
                Write-Host "No files matched for path: $expandedSourcePath"
                continue
            }

            foreach ($file in $sourceFiles) {
                # Copy each file to the destination folder
                $destinationFilePath = Join-Path -Path $fullDestinationFolder -ChildPath $file.Name
                Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
                Write-Host "Copied file $($file.FullName) to $destinationFilePath"
            }
        }
    }
}
