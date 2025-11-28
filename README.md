

Template for self hosted nextcloud instance using docker and crowdsec as a firewall. Use as a starting point and modify accordingly.
# Structure  
                                                                           
                                     |--------------------------------   Docker network  --------------------------------|
                          [ HOST ]                                      192.168.XXX.0/24
                         __________                     ______________                     ___________          _________
                        |          | <--> :80/:443 <-> | nginx proxy  | <---------------> |           | <----> | mariaDb |
                        |  docker  |                    --------------                    | nextcloud |         ---------
    <--:80/:443-->      |    +     | <---> :3921 <---> | coTurn       |                   |           | <----> | redis   |
                        | crowdsec |                    --------------                     -----------          --------- 
                        | bouncer  | <---> :8080 <---> | crowdSec     | <--[ nginx logs ]     
                        |          |                    --------------                                  
                        |__________| <---> :3000 <---> | crowdSecDash |                      
                                                        --------------            
                                                       | certbot      | -->[ nginx certs ]
                                                        --------------



# Containers
Breif overview:
### nginx
Reverse proxy and https handling.
### certbot
Generates the ssl certs for https connection.
### nextcloud
Cloud server.
### mariaDb
Main database used by the nextcloud container.
### redis
Memory cache for database.  
### coTurn
TURN server for nextcloud video calls. 
### crowdSec
crowdSed security engine. Communitcates via port 8080 to the firewall bouncer on the local host. 
### crowdSecDash
Simple dashboard for metrics from the security engine.

# Deploying
## HTTP
### Host prep
  - install docker <br>
  optional:
     - install pv (used by backup script)
     - set timezone sudo timedatectl set-timezone Europe/Stockholm
     - set locale sudo dpkg-reconfigure
### Docker prep
  - docker compose down
  - total clean:
    - docker volume prune -a
    - docker system prune -a 
  - clean instance ./cleanInstanse.sh (removes nexcloud folder + certbot)
  - configure .env, set passwords for db and correct ip's
### Docker deploy
  - docker compose up --build -d 
### Nextcloud
  - access locally and set admin user
## HTTPS

