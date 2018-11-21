### Airforce Maintenance 
This project was created from the skeleton of the balance transfer sample project. It all includes figures from the marbles sample project and fabcar simple project. 
A sample Node.js app to demonstrate **__fabric-client__** & **__fabric-ca-client__** Node.js SDK APIs

### Prerequisites and setup (See fabric Documentation for me details):
•	Docker – version 1.12 or higher
•	Docker Compose – version 1.8 or higher
•	Git 
•	Node.js – version 8.4.0 or higher

###Air-force-maintenance has the following docker container configuration:
* 2 CAs
* A SOLO orderer
* 4 peers (2 peers per Org)
* 2 Channels(1 channel with 2 Orgs and 1 Channel with 1 Org)
* CouchDB 
* Complex queries


###Running the sample program

You will need two terminal windows
##In the first terminal run the script ./runApp.sh
* This launches the required network on your local machine
* Installs the fabric-client and fabric-ca-client node modules
* And, starts the node app on PORT 4000
##In the second terminal once the script has completed from the first terminal, run ./testAPIs.sh
•	Once the second script finish you can scroll through the terminal and you can see some of the Complex Queries, in data being added the ledgers, and how the Orgs can only access the ledgers of the channels the are assigned too.
•	You can also then use something like Postman to make API calls to the hyper ledger fabric blockchain
