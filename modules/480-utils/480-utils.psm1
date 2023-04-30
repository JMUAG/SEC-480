Function 480Banner()
{
    $banner=@"
    _____   ______ _______       
   /  |  | /  __  \\   _  \      
  /   |  |_>      </  /_\  \     
 /    ^   /   --   \  \_/   \    
 \____   |\______  /\_____  /    
      |__|       \/       \/     
  ____ ___   __  .__.__          
 |    |   \_/  |_|__|  |   ______
 |    |   /\   __\  |  |  /  ___/
 |    |  /  |  | |  |  |__\___ \ 
 |______/   |__| |__|____/____  >
                              \/ 
                                            
"@
    Write-Host $banner
} 

Function 480Connect($server)
{
    $conn = $global:DefaultVIServer
    #are we already connected?
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn

        Write-Host -ForegroundColor "Green" $msg
    }else {
        $conn = Connect-VIServer -Server $server
        #if this fails, let Connect-VIServer handle the exception
    }
}

Function Get-480Config([string] $config_path)
#You want to make $config_path a fully qualifiable path because it will not work
#depending on where you run the code from

{
    $conf=$null
    if(Test-Path $config_path)
    #This is to see if the file exists
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        #Allows you to read the file and then convert it from json to variables
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor "Green" $msg
        #Confirm to the user that you have the requested file
    } else {
        Write-Host -ForegroundColor "Yellow" "No Configuration"
        #Let the user know there is already a configuration or the file is not found
    }
    return $conf
}

Function Select-VM([string] $folder)
{
    $selected_vm=$null
    try 
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        #480-TODO need to deal with an invalid index (consider making this check a function)
        $selected_vm = $vms[$pick_index -1]
        Write-Host ""
        Write-Host "You have selected" $selected_vm.name -ForegroundColor DarkCyan
        #note this is a full on vm object that we can interract with
        return $selected_vm
    }
    catch
    {
        <#Do this if a terminating exception happens#>
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"
    }
}
Function Select-All-VM()
{
    $selected_vm=$null
    try 
    {
        $vms = Get-VM 
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        #480-TODO need to deal with an invalid index (consider making this check a function)
        $selected_vm = $vms[$pick_index -1]
        Write-Host "you picked " $selected_vm.name
        #note this is a full on vm object that we can interract with
        return $selected_vm
    }
    catch
    {
        <#Do this if a terminating exception happens#>
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"
    }
}

Function LinkedClone([string] $folder)
{
    #$input =  Read-Host "What is the name of your VM: "
    $vm = Select-VM -folder $folder
    #$vm = Get-VM -Name $select_vm
    $input1 = Read-Host "What is the name of your base clone: "
    $snapshot = Get-Snapshot -VM $vm -Name $input1
    $input2 = Read-Host "What is the IP of your VM-Host: "
    $vmhost = Get-VMHost -Name $input2
    $input3 = Read-Host "What datastore are you utilizing: "
    $ds = Get-DataStore -Name $input3
    $linkedClone = "{0}.linked" -f $vm.name
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    $input4 = Read-Host "What is the name of your new VM: "
    New-VM -Name $input4 -VM $linkedvm -VMHost $vmhost -Datastore $ds
    #Get-VM $input4
    $linkedvm | Remove-VM
    Get-VM    
} 

Function New-Network([string] $vmhost)
{
    $VSname = Read-Host "What would you like to name this VirtualSwitch?"
    New-VirtualSwitch -VMHost $vmhost -Name $VSname
    Write-Host ""
    Write-Host "Your Virtual Switch has been created" -ForegroundColor Green
    Write-Host ""
    Get-VirtualSwitch
    Write-Host ""
    $PGname = Read-Host "What would you like to name this PortGroup?"
    New-VirtualPortGroup -VirtualSwitch $VSname -Name $PGname
}

Function Get-IP([string] $folder)
{
    $vm = Select-VM -folder $folder
    Write-Host ""


    $adap = Get-NetworkAdapter -vm $vm #| Select-Object Name
    
    $index = 1
    foreach($a in $adap)
        {
            Write-Host [$index] $a.name
            $index+=1
        }
    Write-Host ""
    $pick_index = Read-Host "Which index number [x] do you wish to pick?"
    Write-Host ""
    #480-TODO need to deal with an invalid index (consider making this check a function)
    $selected_adap = $adap[$pick_index -1]
    Write-Host "You have selected" $selected_adap.name -ForegroundColor DarkCyan
    #$MAC = (Get-NetworkAdapter -VM $vm | Select-Object MacAddress)
    #$MAC = SelectAdapter -folder $folder | Select-Object MacAddress
    $MAC = $selected_adap.MacAddress
    $IP = (Get-VM -name $vm).Guest.IPAddress[$pick_index -1]
    Write-Host ""
    Write-Host "IP:$IP MAC:$MAC HOSTNAME:$vm"
    Write-Host ""
}

Function VMStart([string] $folder)
{
    try
    {
        $vm = Select-VM -folder $folder
        Start-VM -VM $vm -Confirm:$false 
        Write-Host ""
    }

    catch {
        Write-Host "It's already powered on!" -ForegroundColor DarkRed
    }
}
Function VMStop([string] $folder)
{
    try{
        $vm = Select-VM -folder $folder
        Stop-VM -VM $vm -Confirm:$false
        Write-Host ""
        
    }
    catch {
        Write-Host "It's already powered off!" -ForegroundColor DarkRed
    }
}
Function Show-Network()
{
    $vm = Select-All-VM
    Get-NetworkAdapter -VM $vm
}
Function SelectAdapter([string] $folder)
{
    $vm = Select-VM($folder)
    $adap = Get-NetworkAdapter -vm $vm #| Select-Object Name
    
   # foreach ($x in $adap) {
   #     Write-Host "Adapter Name: $($x.name)"
    #}
    $index = 1
    foreach($a in $adap)
        {
            Write-Host [$index] $a.name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        #480-TODO need to deal with an invalid index (consider making this check a function)
        $selected_adap = $adap[$pick_index -1]
        Write-Host "you picked " $selected_adap.name
        #note this is a full on vm object that we can interract with
        return $selected_adap
}
Function Set-Network([string] $folder)
{
    Write-Host "The following are your current established networks:"
    Get-VirtualNetwork 
    Write-Host ""
    $adap = SelectAdapter($folder)
    Set-NetworkAdapter -NetworkAdapter $adap -NetworkName (Read-Host -Prompt "Enter the network of your choice") -Confirm:$false 
}


