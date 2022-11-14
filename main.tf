locals {
    allocated_storage        = 10
    engine                   = "mariadb"
    engine_version           = "10.6"
    instance_class           = "db.t3.micro"
    skip_final_snapshot      = true

    username = "admin"
    password = "TopSecret915!"           
    
    snapshot_identifier      = null
    
    source_db_instance_automated_backups_arn = null
    use_latest_restorable_time               = null
    restore_time                             = null
    delete_automated_backups                 = false
}

resource "aws_db_instance" "rds1" {
    identifier               = "rds1"
    allocated_storage        = local.allocated_storage
    engine                   = local.engine
    engine_version           = local.engine_version
    instance_class           = local.instance_class
    username                 = local.username
    password                 = local.password
    skip_final_snapshot      = local.skip_final_snapshot

    snapshot_identifier      = local.snapshot_identifier
    delete_automated_backups = local.delete_automated_backups

    dynamic "restore_to_point_in_time" {

        for_each = local.use_latest_restorable_time == true || local.restore_time != null ? [1] : []

        content {
            source_db_instance_automated_backups_arn = local.source_db_instance_automated_backups_arn
            use_latest_restorable_time               = local.use_latest_restorable_time
            restore_time                             = local.restore_time
        }

    }
}