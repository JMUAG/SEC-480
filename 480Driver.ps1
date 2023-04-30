Import-Module '480-utils' -Force
#Call the Banner Function
480Banner
$conf = Get-480Config -config_path "/home/jahseem-480/SEC-480/480.json"
480Connect -server $conf.vcenter_server
#Write-Host "Selecting your VM"
#Select-All-VM
#LinkedClone($conf.prod_vm_folder)
#New-Network($conf.esxi_host) 
Get-IP($conf.prod_vm_folder)
#VMStart($conf.prod_vm_folder)
#VMStop($conf.prod_vm_folder)
#SelectAdapter($conf.prod_vm_folder) 
#Set-Network($conf.prod_vm_folder)
#Show-Network