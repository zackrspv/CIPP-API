BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $FunctionPath = Join-Path $RepoRoot 'Modules/CIPPCore/Public/Test-CIPPAccessTenant.ps1'

    function Get-Tenants {
        [pscustomobject]@{
            customerId       = $env:TenantID
            defaultDomainName = 'partner.example'
            displayName      = 'Partner Tenant'
        }
    }
    function New-GraphBulkRequest { [pscustomobject]@{ body = [pscustomobject]@{ value = @() } } }
    function Test-CIPPStandardLicense { $true }
    function New-ExoRequest {
        param($tenantid, $cmdlet, $cmdParams)
        if ($cmdlet -eq 'Get-OrganizationConfig') { return [pscustomobject]@{ Name = 'Partner Tenant' } }
        if ($cmdlet -eq 'Get-ManagementRoleAssignment') {
            return [pscustomobject]@{ RoleAssigneeName = 'Organization Management'; Role = 'Mail Recipients'; Guid = 'role-1' }
        }
    }
    function New-GraphGetRequest { throw 'Supplemental Graph surface unavailable' }
    function Get-CippException { param($Exception) [pscustomobject]@{ NormalizedError = $Exception.Exception.Message } }
    function Write-LogMessage { param($headers, $API, $tenant, $tenantId, $message, $Sev, $LogData) }
    function Get-CIPPTable { @{ Table = 'AccessChecks' } }
    function Add-CIPPAzDataTableEntity { param($Table, $Entity, [switch]$Force) }

    . $FunctionPath
}

Describe 'Test-CIPPAccessTenant partner tenant handling' {
    BeforeEach {
        $env:TenantID = '11111111-1111-1111-1111-111111111111'
    }

    It 'keeps Exchange healthy when only the supplemental Graph role comparison fails' {
        $result = Test-CIPPAccessTenant -Tenant $env:TenantID

        $result.GraphStatus | Should -BeTrue
        $result.GraphTest | Should -Match 'direct partner-tenant access'
        $result.ExchangeStatus | Should -BeTrue
        $result.ExchangeTest | Should -Match 'Successfully connected to Exchange'
        $result.ExchangeTest | Should -Match 'Supplemental Organization Management role comparison unavailable'
    }
}
