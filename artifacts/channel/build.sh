#!/bin/bash

./configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesis.block

./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID mychannel

./configtxgen -profile TwoOrgsChannel -outputAnchorPeerUpdate ./Org1MSPanchors.tx -channelID mychannel -asOrg1MSP

./configtxgen -profile TwoOrgsChannel -outputAnchorPeerUpdate ./Org2MSPanchors.tx -channelID mychannel -asOrg2MSP

./configtxgen -profile AirForceChannel -outputCreateChannelTx ./airforce.tx -channelID airforce