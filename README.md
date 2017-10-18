# Redirection Service

A basic CRUD for managing redirection rules, written in Elm and Koa.

## Purpose

1. To manage redirection rules for izettle.com
2. To decouple application concerns into distinct microservices
3. To try and evaluate Elm as well as learn about the functional programming paradigm
4. To have fun!

## Architecture

```

                                     +---------------+          
                                     |               |          
                                     |  Google Oauth |          
                                     |               |          
                                     +---------------+          
                                         |       ^              
                                         |       |  Authenticate
                                         |       |              
                     /rules              v       |              
  +-----------+                      +---------------+          
  |           |--------------------->|               |          
  |  Inugami  |                      |  Redirection  |          
  |           |<---------------------|  Service      |          
  +-----------+                      |               |          
                    [ rule1          +---------------+          
                    , rule2              ^       |              
                    , rule3              |       |              
                    ]                    |       | CRUD / view  
                                         |       |              
                                         |       |              
                                         |       v              
                                     +---------------+          
                                     |               |          
                                     |    Client     |          
                                     |               |          
                                     +---------------+          

```

## Development

Before you begin, make sure you have [node](https://nodejs.org/), [yarn](https://yarnpkg.com/en/) and [postgresql](https://www.postgresql.org/) installed on your machine.

#### Step 1 - Add "redirection-service.izettle-dev.com" to hosts file

```bash
sudo echo "127.0.0.1 redirection-service.izettle-dev.com" >> /etc/hosts
```

#### Step 2 - Configure GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET

Create the following file at `src/server/config/local.js`

```javascript
module.exports = {
  GOOGLE_CLIENT_ID: "",
  GOOGLE_CLIENT_SECRET: ""
}
```

and ask a co-worker for the **correct values**, or find someone with access to the iZettle account at the [Google Developer Console](https://console.developers.google.com).

#### Step 3 - Install the project dependencies and set up the DB

```bash
yarn # installs dependencies
yarn db:recreate # Set up db with seeds
```

#### Step 4 - Launch the website

```bash
yarn start
```
