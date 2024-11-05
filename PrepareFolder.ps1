# Import-Module for YAML parsing (only needed if you use YamlDotNet)
# Install-Module -Name powershell-yaml -Force -Scope CurrentUser
# Import-Module powershell-yaml

# Load YAML file and parse it
$yamlFilePath = "C:\dev\InstallPackageCreation\Files.yaml"
$yamlContent = Get-Content -Path $yamlFilePath -Raw

# Parse YAML to Hashtable
$parsedYaml = ConvertFrom-Yaml -Yaml $yamlContent

# Process each destination and its associated file paths
foreach ($destinationFolder in $parsedYaml.Keys) {
    # Ensure destination folder exists
    if (!(Test-Path -Path $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder -Force
    }

    # Get each source path from YAML
    $sourcePaths = $parsedYaml[$destinationFolder]

    foreach ($sourcePath in $sourcePaths) {
        if (Test-Path -Path $sourcePath -PathType Container) {
            # If sourcePath is a directory, copy entire directory to destination
            $destinationSubFolder = Join-Path -Path $destinationFolder -ChildPath (Split-Path -Leaf $sourcePath)
            Copy-Item -Path $sourcePath -Destination $destinationSubFolder -Recurse -Force
            Write-Host "Copied directory $sourcePath to $destinationSubFolder"
        } else {
            # Handle wildcards or specific files in the source path
            $sourceFiles = Get-ChildItem -Path $sourcePath -File -ErrorAction SilentlyContinue

            if ($null -eq $sourceFiles) {
                Write-Host "No files matched for path: $sourcePath"
                continue
            }

            foreach ($file in $sourceFiles) {
                # Copy each file to the destination folder
                $destinationFilePath = Join-Path -Path $destinationFolder -ChildPath $file.Name
                Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
                Write-Host "Copied file $($file.FullName) to $destinationFilePath"
            }
        }
    }
}
