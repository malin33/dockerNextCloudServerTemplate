# dockerNextCloudServerTemplate
Server example using docker compose for self hosted cloud

# structure 
                                                                            
                                             Docker network
                [ HOST ]                     192.168.XXX.0/24
               __________                     ______________                     ___________          _________
              |          | ---> :80/:443 --> | nginx proxy  | <---------------> |           | <----> | mariaDb |
              |  docker  |                    --------------                    | nextcloud |         ---------
--:80/:443--> |    +     | ----> :3921 ----> | coTurn       |                   |           | <----> | redis   |
              | crowdsec |                    --------------                     -----------          --------- 
              | bouncer  | ----> :8080 ----> | crowdSec     | <--[ nginx logs ]     
              |          |                    --------------                                  
              |__________| ----> :3000 ----> | crowdSecDash |                      
                                              --------------            
                                             | certbot      | -->[ nginx certs ]
                                              --------------
