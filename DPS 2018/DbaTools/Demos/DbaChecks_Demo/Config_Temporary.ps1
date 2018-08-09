#dbachecks – Setting temporary configuration values

# https://claudioessilva.eu/2018/04/24/dbachecks-setting-temporary-configuration-values/

<#
The default

dbachecks works with the values previously saved (for that we use Set-DbcConfig). 
This means that when we start a new session and the last session has changed any configuration, 
that configuration is now, by default, the one that will be used in the new session.

#>

Get-Help Set-DbcConfig -Parameter temporary


<#
-Temporary parameter exists on both Set-DbcConfig and Import-DbcConfig commands.
By using it, you are just changing the values on the current session 
and won’t overwrite the persisted values. This can become in handy in some cases.

#>
