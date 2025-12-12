// Azure VM Backup Policy Module
// Creates a customized backup policy for Azure VMs

@description('Name of the Recovery Services Vault')
param vaultName string

@description('Name of the backup policy')
param policyName string = 'VM-Daily-Backup-Policy'

@description('Time zone for the backup schedule')
param timeZone string = 'W. Europe Standard Time'

@description('Hour of the day for backup (0-23)')
@minValue(0)
@maxValue(23)
param backupHour int = 2

@description('Minute of the hour for backup (0-59)')
@minValue(0)
@maxValue(59)
param backupMinute int = 0

@description('Number of daily backup points to retain')
@minValue(7)
@maxValue(9999)
param dailyRetentionDays int = 30

@description('Enable weekly retention')
param enableWeeklyRetention bool = true

@description('Number of weekly backup points to retain')
@minValue(1)
@maxValue(5163)
param weeklyRetentionWeeks int = 12

@description('Days of week for weekly backup retention')
param weeklyRetentionDays array = ['Sunday']

@description('Enable monthly retention')
param enableMonthlyRetention bool = true

@description('Number of monthly backup points to retain')
@minValue(1)
@maxValue(1188)
param monthlyRetentionMonths int = 12

@description('Week of month for monthly retention')
@allowed(['First', 'Second', 'Third', 'Fourth', 'Last'])
param monthlyRetentionWeek string = 'First'

@description('Day of week for monthly retention')
param monthlyRetentionDay string = 'Sunday'

@description('Enable yearly retention')
param enableYearlyRetention bool = false

@description('Number of yearly backup points to retain')
@minValue(1)
@maxValue(99)
param yearlyRetentionYears int = 1

@description('Month for yearly retention')
@allowed([
  'January'
  'February'
  'March'
  'April'
  'May'
  'June'
  'July'
  'August'
  'September'
  'October'
  'November'
  'December'
])
param yearlyRetentionMonth string = 'January'

@description('Week of month for yearly retention')
@allowed(['First', 'Second', 'Third', 'Fourth', 'Last'])
param yearlyRetentionWeek string = 'First'

@description('Day of week for yearly retention')
param yearlyRetentionDay string = 'Sunday'

@description('Enable instant restore')
param instantRpRetentionRangeInDays int = 2

resource vault 'Microsoft.RecoveryServices/vaults@2025-02-01' existing = {
  name: vaultName
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: vault
  name: policyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRpRetentionRangeInDays: instantRpRetentionRangeInDays
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          '${padLeft(backupHour, 2, '0')}:${padLeft(backupMinute, 2, '0')}:00'
        ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '${padLeft(backupHour, 2, '0')}:${padLeft(backupMinute, 2, '0')}:00'
        ]
        retentionDuration: {
          count: dailyRetentionDays
          durationType: 'Days'
        }
      }
      weeklySchedule: enableWeeklyRetention
        ? {
            daysOfTheWeek: weeklyRetentionDays
            retentionTimes: [
              '${padLeft(backupHour, 2, '0')}:${padLeft(backupMinute, 2, '0')}:00'
            ]
            retentionDuration: {
              count: weeklyRetentionWeeks
              durationType: 'Weeks'
            }
          }
        : null
      monthlySchedule: enableMonthlyRetention
        ? {
            retentionScheduleFormatType: 'Weekly'
            retentionScheduleWeekly: {
              daysOfTheWeek: [monthlyRetentionDay]
              weeksOfTheMonth: [monthlyRetentionWeek]
            }
            retentionTimes: [
              '${padLeft(backupHour, 2, '0')}:${padLeft(backupMinute, 2, '0')}:00'
            ]
            retentionDuration: {
              count: monthlyRetentionMonths
              durationType: 'Months'
            }
          }
        : null
      yearlySchedule: enableYearlyRetention
        ? {
            retentionScheduleFormatType: 'Weekly'
            monthsOfYear: [yearlyRetentionMonth]
            retentionScheduleWeekly: {
              daysOfTheWeek: [yearlyRetentionDay]
              weeksOfTheMonth: [yearlyRetentionWeek]
            }
            retentionTimes: [
              '${padLeft(backupHour, 2, '0')}:${padLeft(backupMinute, 2, '0')}:00'
            ]
            retentionDuration: {
              count: yearlyRetentionYears
              durationType: 'Years'
            }
          }
        : null
    }
    timeZone: timeZone
  }
}

// Outputs
@description('Backup policy resource ID')
output policyId string = backupPolicy.id

@description('Backup policy name')
output policyName string = backupPolicy.name
