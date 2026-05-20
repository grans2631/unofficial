# Install Microsoft Graph PowerShell module
Install-Module Microsoft.Graph -Scope CurrentUser

# Import the module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Calendars.ReadWrite, Group.ReadWrite.All"

# Create a new calendar
$calendar = New-MgUserCalendar -UserId '<User ID>' -BodyParameter @{Name = 'New Calendar'}

# Share the calendar with users or groups
$calendarId = $calendar.Id
$shareRecipients = @(
    @{Email = 'user1@example.com'},
    @{Email = 'group1@example.com'}
)

foreach ($recipient in $shareRecipients) {
    $email = $recipient.Email
    New-MgUserCalendarPermission -UserId '<User ID>' -CalendarId $calendarId -BodyParameter @{
        EmailAddress = @{
            Address = $email
        }
        IsRemovable = $true
        Role = 'write'  # Possible values: 'freeBusyRead', 'limitedRead', 'read', 'write', 'delegate'
    }
}

Write-Output "Calendar created and shared successfully."
