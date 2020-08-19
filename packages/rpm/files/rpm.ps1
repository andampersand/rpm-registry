$command = $args[0]

$registry = "https://raw.githubusercontent.com/andampersand/rpm-registry/master/"

$version = "1.0.1"

if($command -eq "install"){
    $package = $args[1]
    echo "Installing package $($package) from rpm..."
    echo "Loading the rpm registry..."
    Try { 
        $response = Invoke-WebRequest -Uri "$($registry)rpm.json" -Headers @{"Cache-Control"="no-cache"}
        $response = ConvertFrom-Json -InputObject $response.Content
        echo "Requesting package $($package) from the RPM registry..."
        Try {
            $response = Invoke-WebRequest -Uri "$($registry)/packages/$($package)/rpm_package.json" -Headers @{"Cache-Control"="no-cache"}
            $response = ConvertFrom-Json -InputObject $response.Content
            echo "Downloading package $($package)@$($response.version)"
            $required_file_names = $response.required_files | % {$_.name}
            echo "Downloading installer files : $($required_file_names -join ", ")"
            $install_files_path = "installer_files/$($package)@$($response.version)/"
            if(Test-Path $install_files_path -PathType Any){
                Remove-Item -Recurse -Force $install_files_path
            }
            mkdir $install_files_path > $null
            foreach ($file in $response.required_files){
                Try{
                    $file_uri = "$($registry)/packages/$($package)/files/$($file.name)"
                    if($file.foreign){
                        $file_uri = $file.uri
                    }
                    Invoke-WebRequest -Uri $file_uri -OutFile "$($install_files_path)/$($file.name)"
                }Catch{
                    echo "Something went wrong downloading the file $($file)"
                    Write-Host $_.Exception.Message`n
                }
            }
            echo "Launching install script..."
            Invoke-Item -Path "$($install_files_path)/$($response.installer)"

        } Catch {
            echo "Something went wrong. Either the package '$($package)' is not available in the RPM registry or something went wrong with the internet connection."
        }
    } Catch {
        echo "Something went wrong while connecting to the RPM registry. Check your internet connection and the registry uri."
    }
}elseif ($command -eq "version"){
    echo "RPM version: $($version)"
}else {
    echo "Unknown command '$($command)'"
}