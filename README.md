# CopySharePointFileInChunks
Copy large files from Source SharePoint library to Destination SharePoint library into small chunks. In our Case we were facing an issue while copying a file with PS which can cause error on file size greater than 100MB.

SharePoint has a maximum upload size that varies depending upon your version. The migration mode (Insane mode, Normal mode) you use can also affect the total file size you can migrate in SharePoint.So in that case, this script will chunk files in 10MB smaller portions, block size can be increased up to 99MB 

How to Use?
  Simple and easy to use. Change the following ones to get it work:
  
    $DestnationSiteUrl = "https://your-domain.sharepoint.com/sites/xyz" #URL to Configure, in this case Destination is SP Online site URL, it can be set on On-Prem too.
    $DestinationRelativeURL = "/sites/xyz/TestLibrary" #Server Relative URL here with library Name and in case of specific folder name
    $DestinationUserName = "xyz@your-domain.com" #User to be used as SP Online site
    $DestinationPassword =  To make things secure getting input Password -AsSecureString in PS

    $DestnationSiteUrl = "http://intranet/sites/xyz" #URL to Configure, in this case Destination is SP Online site URL, it can be set on On-Prem too.
    $DestinationRelativeURL = "/sites/xyz/TestLibrary/myfile.pptx" #Server Relative URL here with library Name and in case of specific folder name
    $DestinationUserName = "domain\xyz" #User to be used as SP Online site
    $SourcePassword =  To make things secure getting input Password -AsSecureString in PS
    
    $FileNameWithExt =  "xyz.pptx" file name with extension. It can be any type of file which sharepoint supports.
  
  In Order to re-use context initialize that out side the function and pass context as parameter to function
  
  Function Info:
      
        UploadFileInSlice ($DestinationCtx, $SourceCtx, $SourceFileUrl, $DestinationFolderUrl, $fileName, $fileChunkSizeInMB)
    
  Paramters Info:
    
        $DestinationCtx =  Destination SharePoint Client Context of SP Online destination e.g. "https://your-domain.sharepoint.com/sites/xyz".
        $SourceCtx =  Source SharePoint Client Context of on-prem source e.g. "http://intranet/sites/xyz".
        $SourceFileUrl = Server relative URL of file to be copied with library Name and file name and extension e.g "/sites/xyz/TestLibrary/myfile.pptx".
        $DestinationFolderUrl =  Server relative URL of destination folder where file needs to be copied.
        $fileName =  File Name with extension in order to change the file name on destination 
        $fileChunkSizeInMB = Passing an integer between 1-99 as MB
  
  


How if works?
   Function compares file size and chunk size. If file size is less than chunk size then the script will copy the file directly with [Microsoft.SharePoint.Client.File]::SaveBinaryDirect function.
    
   In case of file size is greater than chunk size , script will read bytes and uploads the file into small chunks untill it reaches to the end block of bytes. And thats it! 
  
  
  
Find more about the upload size limitations 
https://support-desktop.sharegate.com/hc/en-us/articles/115000644148.

When copying a file that exceeds one of these limits, ShareGate Desktop signals an error indicating that the file is too large and that the element cannot be created in your destination.

    Maximum upload size for a document in a library
      SharePoint on premises prior to SharePoint 2016: 2 gigabytes
      SharePoint 2016: 10 gigabytes
      SharePoint 2019: 15 gigabytes
      Office 365: 100 gigabytes in Normal mode, 15 gigabytes in Insane mode.

    Maximum upload size for a list item attachment
      SharePoint on premises: 50 megabytes
      Office 365: 250 megabytes



