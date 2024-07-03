Function Check-FTPStatus {
    [cmdletBinding()]
    param(
        # Want to support multiple Computers
        [parameter(
            mandatory=$true,
            valueFromPipeline=$true,                
            ValueFromPipelineByPropertyName=$true,       
            HelpMessage='Enter One or more Computer names to check FTP service status on, Press enter on a blank entry when finished')]
        [Alias('Hostname','Server')]
        [string[]]$ComputerName,

        # Switch to turn on error logging
        [switch]$ErrorLog,

        [string]$LogFile = 'C:.\FTPstatusErrorlog.txt'   # Prints an error log in working directory when -ErrorLog parameter turned on
    )

    Begin {
        if ($ErrorLog) {
            Write-Verbose 'Error Logging turned on'
        } else {
            Write-Verbose 'Error Logging turned off'
        }

        # "-Verbose" parameter is needed to see the results
        Foreach ($C in $ComputerName) {
            Write-Verbose "Computer: $C"
        }
    }

    Process {
        foreach ($C in $ComputerName) {
            try {
                # Check the status of the ftpsvc service
                $service = Get-Service -Name ftpsvc

                if ($service.Status -eq 'Running') {
                    Write-Output "The FTP Service (ftpsvc) is running."
                } else {
                    Write-Warning "The FTP Service (ftpsvc) is Stopped."
                }
            } catch {
                Write-Warning "Error found with Computer '$C'"
                if ($ErrorLog) {
                    $CurrentError = $_.Exception.Message
                    Get-Date | Out-File $LogFile -Force #-Force will overwrite a file if it exists
                    $C | Out-File $LogFile -Append
                    $CurrentError | Out-File $LogFile -Append
                }
            }
        }
    }

    End {
        # End of function
    }
}


Function Get-MachineInfo {
    [cmdletBinding()]
    param(
        # Want to support multiple Computers
        [parameter(
            mandatory=$true,
            valueFromPipeline=$true,                
            ValueFromPipelineByPropertyName=$true,       
            HelpMessage='Enter One or more Computer names to get Info from, Press enter on a blank entry when finished')]
        [Alias('Hostname','Server')]
        [string[]]$ComputerName,

        # Switch to turn on error logging
        [switch]$ErrorLog,

        [string]$LogFile = 'C:.\errorlog.txt'    # Prints an error log in working directory when -ErrorLog parameter turned on
    )

    Begin {
        if ($ErrorLog) {
            Write-Verbose 'Error Logging turned on'
        } else {
            Write-Verbose 'Error Logging turned off'
        }

        # "-Verbose" parameter is needed to see the results
        Foreach ($C in $ComputerName) {
            Write-Verbose "Computer: $C"
        }
    }

    Process {
        foreach ($C in $ComputerName) {
            try {
                $os = Get-WmiObject -ComputerName $C -Class Win32_OperatingSystem -ErrorAction Stop -ErrorVariable CurrentError
                $disk = Get-WmiObject -ComputerName $C -Class Win32_LogicalDisk -filter "DeviceID='c:'"
                $Bios = Get-WmiObject -ComputerName $C -Class Win32_bios    
                $FreeSpacePercentage = ($disk.FreeSpace / $disk.Size) * 100 -as [int]

                if ($FreeSpacePercentage -le 75) {
                    Write-Warning "'$C' is at 75% or more maximum disk Capacity"
                }

                $Prop = [ordered]@{                            
                    'ComputerName' = $C             
                    'OS Name' = $os.caption
                    'OS Build' = $os.buildnumber
                    'Bios Version' = $Bios.version
                    'TotalSpace' = $disk.Size / 1gb -as [int]
                    'FreeSpace' = $disk.freespace / 1gb -as [int]
                    'FreeSpacePercentage' = $FreeSpacePercentage
                }

                $obj = New-Object -TypeName PSObject -Property $Prop
                Write-Output $obj
            } catch {
                Write-Warning "Error found with Computer '$C'"
                if ($ErrorLog) {
                    Get-Date | Out-File $LogFile -Force #-Force will overwrite a file if it exists
                    $C | Out-File $LogFile -Append
                    $CurrentError | Out-File $LogFile -Append
                }
            }
        }
    }

    End {
        # End of function
    }
}
