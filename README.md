## Deploy

`bin/cap production deploy`


## Process monitoring with eye (production only)
Logs and pids  are located in capistrano shared folder

#### Get info
`eye w`

#### Stop and quit all monitoring 
`eye q -s`

#### Start monitoring
`eye l /home/ec2-user/apps/tipper/current/tipper.eye' 
