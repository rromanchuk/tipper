## Deploy

`bin/cap production deploy`

`bin/cap production deploy:restart`

## Process monitoring with leye (production only)
Logs and pids  are located in capistrano shared folder

#### Get info
`leye w`

#### Stop and quit all monitoring
`leye q -s`

#### Start monitoring
`leye load` from current release path
