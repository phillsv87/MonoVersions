#!/usr/bin/env pwsh
param(
    [string]$src=$(throw "-src required"),
    [switch]$overwrite
)
$ErrorActionPreference="Stop"

$fileDir=[System.IO.Path]::GetDirectoryName($src)
$src=[System.IO.Path]::GetFileName($src)

Push-Location $fileDir
try{
    $dir='tmp_'+$src.Replace('.','_')
    if($overwrite){
        rm -rf $dir
    }
    if(!(Test-Path $dir)){
        pkgutil --expand "$src" "$dir"
        if($?){
            Write-Host "Expanded to $dir"  -ForegroundColor Cyan
        }else{
            mv $src $dir
            if($?){
                Write-Host "Renamed $src to $dir" -ForegroundColor Cyan
            }else{
                throw "Failed to rename $src to $dir"
            }

        }
    }

    Push-Location "$dir"
    try{
        if(Test-Path "Payload"){
            $payloadDir="payload-content"
            if($overwrite){
                rm -rf $payloadDir
            }
            if(!(Test-Path $payloadDir)){
                mkdir $payloadDir
                tar xvf Payload -C "$payloadDir"
                if($?){
                    Write-Host "Extracted Payload" -ForegroundColor DarkGreen
                }else{
                    throw "Extract Payload failed"
                }
            }
            Push-Location $payloadDir
            try{
                return Get-Location
            }finally{
                Pop-Location
            }
        }else{
            Write-Host "No Payload found - $(Get-Location)/Payload. Check for sub packages" -ForegroundColor DarkYellow
            return Get-Location
        }
    }finally{
        Pop-Location
    }
}finally{
    Pop-Location
}