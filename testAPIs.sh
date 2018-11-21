#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./testAPIs.sh -l golang|node"
  echo "    -l <language> - chaincode language (defaults to \"golang\")"
}
# Language defaults to "golang"
LANGUAGE="golang"

# Parse commandline args
while getopts "h?l:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
  esac
done

##set chaincode path
function setChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_SRC_PATH="github.com/example_cc/go"
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/example_cc/node"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

setChaincodePath

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=Org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=Org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo
echo
echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo

echo "POST request Create Airforce channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"airforce",
	"channelConfigPath":"../artifacts/channel/airforce.tx"
}'
echo
echo
sleep 5

echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer1.org1.example.com"]
}'
echo
echo

echo "POST request Join channel on Org2"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org2.example.com","peer1.org2.example.com"]
}'
echo
echo
echo "POST request Join Airforce channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/airforce/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer1.org1.example.com"]
}'
echo
echo

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST instantiate chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"mycc\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST instantiate chaincode on Org1 on Airforce channel"
echo
curl -s -X POST \
  http://localhost:4000/channels/airforce/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"mycc\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST invoke chaincode on peers of Org1 and Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer0.org2.example.com"],
	"fcn":"initLedger",
	"args":["a","b","10"]
}')
echo "Transaction ID is $TRX_ID"
echo
echo

#Add maintenance to mychannel Channel
echo "POST ADD mychannel maintenance"
echo
Add_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/ \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"createNewMaintenance",
	"args":["Maintenance4", "1542749142", "1574285141", "700C", "0002549"]
}')
echo "ADD ID is $Add_Response"
echo
echo

#Add maintenance to Air Force Channel
echo "POST ADD Airforce Maintenance"
echo
Add_Response=$(curl -s -X POST \
  http://localhost:4000/channels/airforce/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"createNewMaintenance",
	"args":["Maintenance5", "1574285141", "1605907541", "1000C", "0002456"]
}')
echo "ADD ID is $Add_Response"
echo
echo

#Query all data from mychannel 
echo "POST Query all data reponses"
echo
Q_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"showAllHvacMaintenance",
	"args":[]
}')
echo "Query ID is $Q_Response"
echo
echo

#Query a Single Query from mychannel
echo "POST Single Query data reponses"
echo
QS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"showSingleMaintenance",
	"args":["Maintenance1"]
}')
echo "Single Query ID is $QS_Response"
echo
echo

#Query a Single Query from Air Force Channel with ORG_1 to make sure it can't read airforce channel *TEST
echo "POST Single Query Airforce data reponses"
echo
QS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/airforce/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"showSingleMaintenance",
	"args":["Maintenance5"]
}')
echo "Single Query ID is $QS_Response"
echo
echo

#Query a Single Query from Air Force Channel with ORG_2 that is part of the channel 
echo "POST Single Query Airforce data reponses test Org2"
echo
QS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/airforce/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"showSingleMaintenance",
	"args":["Maintenance5"]
}')
echo "Single Query ID is $QS_Response"
echo
echo

#Query a Single Query from the mychannel Channel with ORG_2 checking to make sure maintenance5 wasn't added to mychannel *TEST
echo "POST Single Query mychannel data reponses test Org2"
echo
QS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"showSingleMaintenance",
	"args":["Maintenance5"]
}')
echo "Single Query ID is $QS_Response"
echo
echo

#Query mychannel by Installer Id
echo "POST Query by Installer Id data reponses"
echo
IDS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"filterByInstallerID",
	"args":["0005679"]
}')
echo "Installer ID Query is $IDS_Response"
echo
echo

#Query mychannel by Install Date - less then
echo "POST Query by Install Date data reponses"
echo
IDS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"filterByInstallDates",
	"args":["1542931200"]
}')
echo "Install Date ID Query is $IDS_Response"
echo
echo

#Query mychannel by Maintenance Date - greater then
echo "POST Query by Maintenance Date data reponses"
echo
IDS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"filterByMaintenanceDate",
	"args":["1548201600"]
}')
echo "Maintenance Date ID Query is $IDS_Response"
echo
echo

#Query mychannel by Building ID
echo "POST Query by Building ID data reponses"
echo
IDS_Response=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"filterByBuildingId",
	"args":["400C"]
}')
echo "Building ID Query is $IDS_Response"
echo
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
exit

echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/mycc?peer=peer0.org1.example.com&fcn=query&args=%5B%22a%22%5D" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Block by blockNumber"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/blocks/1?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Transaction by TransactionID"
echo
curl -s -X GET http://localhost:4000/channels/mychannel/transactions/$TRX_ID?peer=peer0.org1.example.com \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

############################################################################
### TODO: What to pass to fetch the Block information
############################################################################
#echo "GET query Block by Hash"
#echo
#hash=????
#curl -s -X GET \
#  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
#  -H "authorization: Bearer $ORG1_TOKEN" \
#  -H "cache-control: no-cache" \
#  -H "content-type: application/json" \
#  -H "x-access-token: $ORG1_TOKEN"
#echo
#echo

echo "GET query ChainInfo"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Installed chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Instantiated chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Channels"
echo
curl -s -X GET \
  "http://localhost:4000/channels?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
