#!/usr/bin/env pwsh
param(
    [string]$version=$(throw "-version required")
)
$ErrorActionPreference="Stop"

$Env:PATH="$PSScriptRoot/../versions/$($version)/Versions/$version/bin:$Env:PATH"