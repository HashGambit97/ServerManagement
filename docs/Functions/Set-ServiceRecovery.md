---
external help file: ServerManagement-help.xml
Module Name: ServerManagement
online version: http://psservermanagement.readthedocs.io/en/latest/functions/Invoke-LogRotation
schema: 2.0.0
---

# Set-ServiceRecovery

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Name (Default)
```
Set-ServiceRecovery [-Name] <String> [-ComputerName <String>] -FirstAction <String> [-SecondAction <String>]
 [-SubsequentAction <String>] [-RestartTime <Int32>] [-ResetCounter <Int32>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### DisplayName
```
Set-ServiceRecovery [-DisplayName] <String> [-ComputerName <String>] -FirstAction <String>
 [-SecondAction <String>] [-SubsequentAction <String>] [-RestartTime <Int32>] [-ResetCounter <Int32>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
{{ Fill DisplayName Description }}

```yaml
Type: String
Parameter Sets: DisplayName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FirstAction
{{ Fill FirstAction Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: NoAction, RunProgram, Restart, Reboot

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ResetCounter
{{ Fill ResetCounter Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RestartTime
{{ Fill RestartTime Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecondAction
{{ Fill SecondAction Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: NoAction, RunProgram, Restart, Reboot

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubsequentAction
{{ Fill SubsequentAction Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: NoAction, RunProgram, Restart, Reboot

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
