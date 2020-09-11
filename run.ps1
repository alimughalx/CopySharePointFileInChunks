Add-Type –Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Function UploadFileInSlice ($DestinationCtx, $SourceCtx, $SourceFileUrl, $DestinationFolderUrl, $fileName, $fileChunkSizeInMB) {
    
    # Each sliced upload requires a unique ID.
    $UploadId = [GUID]::NewGuid()

    # Get File by Server Relative URL
    $File = $SourceCtx.Web.GetFileByServerRelativeUrl($SourceFileUrl)
    $SourceCtx.Load($File)

    # Get file Steam with OpenBinarySteam
    $StreamToUpload = $File.OpenBinaryStream() 
    $SourceCtx.ExecuteQuery()

    # File size in bytes
    $FileSize = ($File).length  

    # Get Destination Folder by Server Relative URL
    $DestinationFolder = $DestinationContext.Web.GetFolderByServerRelativeUrl($DestinationFolderUrl)
    $DestinationCtx.Load($DestinationFolder)
    $DestinationCtx.ExecuteQuery()

    # Set Complete Destination URL with Destination Folder + FileName
    $destUrl = $DestinationFolderUrl + "/" + $fileName
    # File object.
    [Microsoft.SharePoint.Client.File] $upload

    # Calculate block size in bytes.
    $BlockSize = $fileChunkSizeInMB * 1000 * 1000 
    Write-Host "File Size is: $FileSize bytes and Chunking Size is:$BlockSize bytes"

    if ($FileSize -le $BlockSize)
    {
        # Use regular approach if file size less than BlockSize
        Write-Host "File uploading with out chunking"
        $upload =[Microsoft.SharePoint.Client.File]::SaveBinaryDirect($DestinationCtx, $destUrl, $StreamToUpload.Value, $true)
        return $upload
    }
    else
    {
        # Use large file upload approach.
        $BytesUploaded = $null
        $Fs = $null
        
        Try {
            $br = New-Object System.IO.BinaryReader($StreamToUpload.Value)
            
            #$br = New-Object System.IO.BinaryReader($Fs)
            $buffer = New-Object System.Byte[]($BlockSize)
            $lastBuffer = $null
            $fileoffset = 0
            $totalBytesRead = 0
            $bytesRead
            $first = $true
            $last = $false
            # Read data from file system in blocks. 
            while(($bytesRead = $br.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $totalBytesRead = $totalBytesRead + $bytesRead
                # You've reached the end of the file.
                if($totalBytesRead -eq $FileSize) {
                    $last = $true
                    # Copy to a new buffer that has the correct size.
                    $lastBuffer = New-Object System.Byte[]($bytesRead)
                    [array]::Copy($buffer, 0, $lastBuffer, 0, $bytesRead)
                }

                If($first)
                {
                    $ContentStream = New-Object System.IO.MemoryStream
                    # Add an empty file.
                    $fileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                    $fileCreationInfo.ContentStream = $ContentStream
                    $fileCreationInfo.Url = $fileName
                    $fileCreationInfo.Overwrite = $true
                    #Add file to Destination Folder with file creation info
                    $Upload = $DestinationFolder.Files.Add($fileCreationInfo)
                    $DestinationCtx.Load($Upload)

                    # Start upload by uploading the first slice.
                    $s = New-Object System.IO.MemoryStream(,$Buffer)
                    Write-Host "Uploading id is:"+$UploadId
                    # Call the start upload method on the first slice.
                    $BytesUploaded = $Upload.StartUpload($UploadId, $s)
                    $DestinationCtx.ExecuteQuery()

                    # fileoffset is the pointer where the next slice will be added.
                    $fileoffset = $BytesUploaded.Value
                    Write-Host "First patch of file with bytes"+ $fileoffset 
                    # You can only start the upload once.
                    $first = $false
                }
                Else
                {
                    # Get a reference to your file.
                    $Upload = $DestinationCtx.Web.GetFileByServerRelativeUrl($destUrl);
                    If($last) {
                        # Is this the last slice of data?
                        $s = New-Object System.IO.MemoryStream(,$lastBuffer)

                        # End sliced upload by calling FinishUpload.
                        $Upload = $Upload.FinishUpload($UploadId, $fileoffset, $s)
                        $DestinationCtx.ExecuteQuery()

                        Write-Host "File Upload Completed Successfully!"
                        # Return the file object for the uploaded file.
                        return $Upload
                    }
                    else {
                        $s = New-Object System.IO.MemoryStream(,$buffer)
                        # Continue sliced upload.
                        $BytesUploaded = $Upload.ContinueUpload($UploadId, $fileoffset, $s)
                        $DestinationCtx.ExecuteQuery()

                        # Update fileoffset for the next slice.
                        $fileoffset = $BytesUploaded.Value
                        Write-Host "File uploading is in progress with bytes: "+ $fileoffset 
                    }
                }

            }  #// while ((bytesRead = br.Read(buffer, 0, buffer.Length)) > 0)
        }
        Catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        Finally {
            if ($Fs -ne $null)
            {
                $Fs.Dispose()
            }
        }
    }
    return $null
}

#URL to Configure, in this case Destination is SP Online site URL
#Adding up credentials hard-code, you can use Get-Credentails PS command too
$DestnationSiteUrl = "https://your-domain.sharepoint.com/sites/xyz"
$DestinationRelativeURL = "/sites/xyz/TestLibrary" #server relative URL here with library Name and Folder name
$DestinationUserName = "xyz@your-domain.com"
$DestinationPassword = Read-Host "Enter Password for Destination User: $DestinationUserName" -AsSecureString

#URL to Configure, in this case Source is On-Prem site URL
#Adding up credentials hard-code, you can use Get-Credentails PS command too
$SourceSiteUrl = "http://intranet/sites/xyz"
$SourceRelativeURL = "/sites/xyz/TestLibrary/myfile.pptx" #server relative URL here with library Name and file name with extension
$SourceUsername = "domain\xyz"

#Set a file name with extension
$FileNameWithExt = "myfile.pptx"

#Get Source Client Context with credentials 
$SourceContext = New-Object Microsoft.SharePoint.Client.ClientContext($SourceSiteUrl) 
#Using NetworkCredentials in case of On-Prem
$SourceCtxcredentials = New-Object System.Net.NetworkCredential($SourceUsername, $SourcePassword)
$SourceContext.RequestTimeout = [System.Threading.Timeout]::Infinite
$SourceContext.ExecuteQuery();

#Get Destination Client Context with credentials 
$DestinationContext = New-Object Microsoft.SharePoint.Client.ClientContext($DestnationSiteUrl) 
#Using SharePointOnlineCredentials in case of SP-Online
$DestinationContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($DestinationUserName, $DestinationPassword)
$DestinationContext.RequestTimeout = [System.Threading.Timeout]::Infinite
$DestinationContext.ExecuteQuery();

#All Set up, now just call the UploadFileInSlice with parameters
$UpFile = UploadFileInSlice -DestinationCtx $DestinationContext -SourceCtx $SourceContext -DestinationFolderUrl $DestinationRelativeURL -SourceFileUrl $SourceRelativeURL -fileName $FileNameWithExt -fileChunkSizeInMB 10
