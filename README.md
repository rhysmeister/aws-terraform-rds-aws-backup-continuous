# aws-terraform-rds-aws-backup-continuous

A simple extension of [aws-terraform-rds-aws-backup](https://github.com/rhysmeister/aws-terraform-rds-aws-backup) implementing continuous backup as well as snapshot and point-in-time restore capabilities.

# Initial deployment & PITR Demo

Ensure that the following variables are all set to null for the initial deployment...

* snapshot_identifier
* source_db_instance_automated_backups_arn
* use_latest_restorable_time
* restore_time

```bash
terraform apply
```

Allow some time to pass for the AWS Backup job to run and that a valid restore point exists. After some time has passed... let's assume an "db incident" has happened and we want to PITR our db. First we need to break the association between our db instance and the continuous backup.

AWS Backups > Backup vaults > rds-backup-vault (There should be at least 1 recovery point available. Wait for one to appear if not.)

Find the recovery point and select it
Actions > Delete (yes really)
Choose "Disassociate recovery point"
Confirm

Then we can destroy the db instance (does this make you nervous too?)

```bash
terraform destroy --target aws_db_instance.rds1
```

Back in the AWS Web Console...

RDS > Automated Backups > Retained
In the section titled "Retained Backups" you will see one for rds1.
Click on rds1
Copy the ARN at the top of the page, i.e arn:aws:rds:eu-central-1:824543128771:auto-backup:ab-etzjhgxbboizmdkpcl7vjtrxvtlgccl35knapbq
Note the restorable datetimes (You'lll need to modify these to UTC).
Back in the main.tf file set...

source_db_instance_automated_backups_arn = ARN we copied above
restore_time = The datetime to restore to, i.e. 2022-11-14T15:12:00.05Z

Then we can restore...

```bash
terraform apply
```

Wait for the restore to complete.

RDS > DB Instances > rds1 > Logs & Events
You should see a message confirming the restore. Something like...

	Restored from DB instance rds1 to 2022-11-14 15:12:00.05

# Clean up

# Bug with restore_to_point_in_time?

    It seems when the restore_to_point-in_time block has values all set to null, it causes this error...

    │ Error: Plugin did not respond
    │ 
    │   with aws_db_instance.rds1,
    │   on main.tf line 18, in resource "aws_db_instance" "rds1":
    │   18: resource "aws_db_instance" "rds1" {
    │ 
    │ The plugin encountered an error, and failed to respond to the plugin.(*GRPCProvider).ApplyResourceChange
    │ call. The plugin logs may contain more details.
    ╵

    Stack trace from the terraform-provider-aws_v4.38.0_x5 plugin:

    panic: interface conversion: interface {} is nil, not map[string]interface {}

    goroutine 386 [running]:
    github.com/hashicorp/terraform-provider-aws/internal/service/rds.resourceInstanceCreate(0xc003730800, {0xa722960?, 0xc0011c4000})
            github.com/hashicorp/terraform-provider-aws/internal/service/rds/instance.go:1097 +0x7145
    github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema.(*Resource).create(0xcab0d60?, {0xcab0d60?, 0xc00321fb60?}, 0xd?, {0xa722960?, 0xc0011c4000?})
            github.com/hashicorp/terraform-plugin-sdk/v2@v2.24.0/helper/schema/resource.go:695 +0x178
    github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema.(*Resource).Apply(0xc0012b0ee0, {0xcab0d60, 0xc00321fb60}, 0xc0035a5ad0, 0xc003730680, {0xa722960, 0xc0011c4000})
            github.com/hashicorp/terraform-plugin-sdk/v2@v2.24.0/helper/schema/resource.go:837 +0xa85
    github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema.(*GRPCProviderServer).ApplyResourceChange(0xc000210000, {0xcab0d60?, 0xc00321fa40?}, 0xc0019db860)
            github.com/hashicorp/terraform-plugin-sdk/v2@v2.24.0/helper/schema/grpc_provider.go:1021 +0xe8d
    github.com/hashicorp/terraform-plugin-mux/tf5muxserver.muxServer.ApplyResourceChange({0xc0025274a0, 0xc002527500, {0xc00392f5e0, 0x2, 0x2}, 0xc0025274d0, 0xc00254c490, 0xc003550140, 0xc002527530}, {0xcab0d60, ...}, ...)
            github.com/hashicorp/terraform-plugin-mux@v0.7.0/tf5muxserver/mux_server_ApplyResourceChange.go:27 +0x142
    github.com/hashicorp/terraform-plugin-go/tfprotov5/tf5server.(*server).ApplyResourceChange(0xc001dab9a0, {0xcab0d60?, 0xc00321e3f0?}, 0xc003728310)
            github.com/hashicorp/terraform-plugin-go@v0.14.0/tfprotov5/tf5server/server.go:818 +0x574
    github.com/hashicorp/terraform-plugin-go/tfprotov5/internal/tfplugin5._Provider_ApplyResourceChange_Handler({0xb8034a0?, 0xc001dab9a0}, {0xcab0d60, 0xc00321e3f0}, 0xc0037282a0, 0x0)
            github.com/hashicorp/terraform-plugin-go@v0.14.0/tfprotov5/internal/tfplugin5/tfplugin5_grpc.pb.go:385 +0x170
    google.golang.org/grpc.(*Server).processUnaryRPC(0xc0033c8d20, {0xcab8860, 0xc003a46680}, 0xc00371b200, 0xc00399bef0, 0x125ae820, 0x0)
            google.golang.org/grpc@v1.48.0/server.go:1295 +0xb2b
    google.golang.org/grpc.(*Server).handleStream(0xc0033c8d20, {0xcab8860, 0xc003a46680}, 0xc00371b200, 0x0)
            google.golang.org/grpc@v1.48.0/server.go:1636 +0xa2f
    google.golang.org/grpc.(*Server).serveStreams.func1.2()
            google.golang.org/grpc@v1.48.0/server.go:932 +0x98
    created by google.golang.org/grpc.(*Server).serveStreams.func1
            google.golang.org/grpc@v1.48.0/server.go:930 +0x28a

    Error: The terraform-provider-aws_v4.38.0_x5 plugin crashed!

    This is always indicative of a bug within the plugin. It would be immensely
    helpful if you could report the crash with the plugin's maintainers so that it
    can be fixed. The output above should help diagnose the issue.

Using a dynamic block should resolve this. UPDATE: It did.

# Notes

*  ~~Disassociating a continuous backup appears to delete it from AWS Backup. To clarify. ~~ Nope, it can be found in RDS > Automated Backups > Retained Backups.