$primaryRG = get-AutomationVariable -Name "primaryRG"
$primaryKV = get-AutomationVariable -Name "primaryKV"
$secondaryRG = Get-AutomationVariable -Name 'secondaryRG'
$secondaryKV = get-AutomationVariable -Name "secondaryKV"
$cloud = get-AutomationVariable -Name "Cloud"

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Write-Output $conn
Connect-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint -Environment $cloud

Get-AzureKeyVaultSecret -VaultName $primaryKV | Where-Object ContentType -ne "application/x-pkcs12" | ForEach-Object {
    $SecretName = $_.Name
    $SourceSecret = Get-AzureKeyVaultSecret -VaultName $primaryKV -Name $SecretName

    $DestinationSecret = Get-AzureKeyVaultSecret -VaultName $secondaryKV -Name $SecretName
    if (!($DestinationSecret) -or ($DestinationSecret.Updated -lt $SourceSecret.Updated))
    {
        Set-AzureKeyVaultSecret -VaultName $secondaryKV -Name $SecretName -SecretValue $SourceSecret.SecretValue -ContentType txt
    }
    else
    {
        Write-Verbose -Message "Secret: $SecretName already up to date" -Verbose
    }
}

# Currently, Key and Certificate can't be updated, so would need to be removed/recreated. Commented out because of this. 

# Get-AzureKeyVaultKey -VaultName $primaryKV | Foreach-Object {
#     $KeyName = $_.Name
#     $SourceKey = Get-AzureKeyVaultKey -VaultName $primaryKV -Name $KeyName
#     $DestinationKey = Get-AzureKeyVaultKey -VaultName $secondaryKV -Name $KeyName
#     if (!($DestinationKey) -or ($DestinationKey.Updated -lt $SourceKey.Updated))
#     {
#         $fn = backup-AzureKeyVaultKey -VaultName $primaryKV -Name $KeyName
#         restore-AzureKeyVaultKey -VaultName $secondaryKV -InputFile $fn
#         remove-item -Path $fn
#     }
# }

# Get-AzureKeyVaultCertificate -VaultName $primaryKV | ForEach-Object {
#     $KeyName =  $_.Name
#     $SourceCertificate = Get-AzureKeyVaultCertificate -VaultName $primaryKV -Name $KeyName
#     $DestinationCertificate = Get-AzureKeyVaultCertificate -VaultName $secondaryKV -Name $KeyName
#     if (!($DestinationCertificate) -or ($DestinationCertificate.Updated -lt $SourceCertificate.Updated))
#     {
#         $fn = backup-AzureKeyVaultCertificate -VaultName $primaryKV -Name $KeyName
#         restore-AzureKeyVaultCertificate -VaultName $secondaryKV -InputFile $fn
#         remove-item -Path $fn
#     }
# }