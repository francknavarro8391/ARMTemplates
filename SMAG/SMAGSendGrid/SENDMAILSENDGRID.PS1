$Username ="azure_15982e4824605b7ca3a890032c7ed4c6@azure.com"
$Password = ConvertTo-SecureString "**********************************************************" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $Username, $Password
$SMTPServer = "smtp.sendgrid.net"
$EmailFrom = "admin@acme.com"
$EmailTo = "***.***@***.***"
$Subject = "SendGrid test"
$Body = "SendGrid testing successful"

Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body