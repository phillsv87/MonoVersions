#!/usr/bin/env pwsh
param(
    [string]$src=$(throw "-src required")
)
$ErrorActionPreference="Stop"

$name=[System.IO.Path]::GetFileNameWithoutExtension($src)

$pkDir=[System.IO.Path]::GetDirectoryName($src)+'/tmp_'+[System.IO.Path]::GetFileName($src).Replace('.','_')


mkdir -p "$PSScriptRoot/versions/"

Write-Host "Installing $name" -ForegroundColor Cyan

$path=&"$PSScriptRoot/ExtractPkg.ps1" -src $src -overwrite

if(Test-Path "$path/mono.pkg"){
    $path=&"$PSScriptRoot/ExtractPkg.ps1" -src "$path/mono.pkg" -overwrite
}elseif(Test-Path "$path/tmp_mono_pkg/payload-content"){
    $path="$path/tmp_mono_pkg/payload-content"
    Write-Host "Using existing mono package $path/tmp_mono_pkg/payload-content"
}

$fw="$path/Library/Frameworks/Mono.framework"
Write-Host "fw = $fw"

if(!(Test-Path "$fw")){
    throw "Framework directory not found - $fw"
}

$installDir="$PSScriptRoot/versions/"
$linkDir=$fw
Push-Location $linkDir
try{

    $v=(Get-ChildItem ./Versions | Where-Object{ $_.Name -ne "Current" } | Select-Object -First 1).Name
    
    if(!(Test-Path "Versions/$v")){
        throw "Versions dir not found in package"
    }

    $installDir+=$v

    foreach($file in Get-ChildItem){
        if($file.LinkType -eq 'SymbolicLink' -and $file.Target.StartsWith('/Library/Frameworks/Mono.framework/Versions/Current')){
            $to=$file.Target.Replace('/Library/Frameworks/Mono.framework/Versions/Current',"$installDir/Versions/$v")
            rm "$($file.FullName)"
            ln -s "$to" "$linkDir/$($file.Name)"

            Write-Host "link $to -> $linkDir/$($file.Name)"
        }
    }

    if(Test-Path "./Versions/Current"){
        rm -rf "./Versions/Current"
        ln -s "$installDir/Versions/$v" "./Versions/Current"
    }


}finally{
    Pop-Location
}

Write-Host "Root access required to finish install" -ForegroundColor Cyan

sudo rm -rf $installDir
if(!$?){
    throw "Remove previous version failed"
}

mv $fw $installDir
if(!$?){
    throw "Move version failed"
}

# Mono framework should be owned by root
sudo chown -R root:admin $installDir
if(!$?){
    throw "Change install dir owner to root failed"
}

Write-Host "Installed $name into $installDir" -ForegroundColor DarkGreen

rm -rf "$pkDir"
