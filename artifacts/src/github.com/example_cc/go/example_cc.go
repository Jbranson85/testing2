/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
 * The sample smart contract for documentation topic:
 * Writing Your First Blockchain Application
 */

 package main

 /* Imports
  * 4 utility libraries for formatting, handling bytes, reading and writing JSON, and string manipulation
  * 2 specific Hyperledger Fabric specific libraries for Smart Contracts
  */
 import (
	 "bytes"
	 "encoding/json"
	 "fmt"
	 "strconv"
	 
	 "github.com/hyperledger/fabric/core/chaincode/shim"
	 sc "github.com/hyperledger/fabric/protos/peer"
 )
 
 // Define the Smart Contract structure
 type SmartContract struct {
 }
 
 type HvacMaintenance struct {
	 DateInstalled int `json:"Date Installed"`
	 MaintenanceDate int `json:"Maintenance Date"`
	 BuildingId string `json:"Building Id"`
	 InstallerId string `json:"Installer Id"`
	 
 }
 
 /*
  * The Init method is called when the Smart Contract "fabcar" is instantiated by the blockchain network
  * Best practice is to have any Ledger initialization in separate function -- see initLedger()
  */
 func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	 return shim.Success(nil)
 }
 
 /*
  * The Invoke method is called as a result of an application request to run the Smart Contract "fabcar"
  * The calling application program has also specified the particular smart contract function to be called, with arguments
  */
 func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
 
	 // Retrieve the requested Smart Contract function and arguments
	 function, args := APIstub.GetFunctionAndParameters()
	 // Route to the appropriate handler function to interact with the ledger appropriately
	 if function == "showSingleMaintenance" {
		 return s.showSingleMaintenance(APIstub, args)
	 } else if function == "initLedger" {
		 return s.initLedger(APIstub)
	 } else if function == "createNewMaintenance" {
		 return s.createNewMaintenance(APIstub, args)
	 } else if function == "showAllHvacMaintenance" {
		 return s.showAllHvacMaintenance(APIstub)
	 } else if function == "filterByInstallerID" {
		return s.filterByInstallerID(APIstub, args)
	 }else if function == "filterByInstallDates" {
		 return s.filterByInstallDates(APIstub, args)
	 }else if function == "filterByMaintenanceDate"{
		 return s.filterByMaintenanceDate(APIstub, args)
	 }else if function == "filterByBuildingId"{
		 return s.filterByBuildingId(APIstub, args)
	 } 
 
	 return shim.Error("Invalid Smart Contract function name.")
 }

 //Function to show a single Maintenance
 func (s *SmartContract) showSingleMaintenance(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
 
	 if len(args) != 1 {
		 return shim.Error("Incorrect number of arguments. Expecting 1")
	 }
	 
	 filterAsBytes, _ := APIstub.GetState(args[0])//Convert to bytes
	 return shim.Success(filterAsBytes)
 }

 //Function to filter by Installer ID
 func (s *SmartContract) filterByInstallerID(APIstub shim.ChaincodeStubInterface, args []string) sc.Response{

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	installer := args[0]

	queryString := fmt.Sprintf("{\"selector\":{\"Installer Id\":\"%s\"}}", installer)//using selector used in couchdb for sorting
	queryResults, err := getQueryResultForQueryString(APIstub, queryString)

	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
 }

 //Function to filter by Install Dates that are less than
 func (s *SmartContract)filterByInstallDates(APIstub shim.ChaincodeStubInterface, args []string) sc.Response{

	if len(args) < 1{
		return shim.Error("Inccorect number of arguments. Expecting 1")
	}
	dateInstalled,_ := strconv.Atoi(args[0])//convert string to int

	queryString := fmt.Sprintf("{\"selector\":{\"Date Installed\": { \"$lt\": %d}}}", dateInstalled) //using selector from couchdb and check if dates is less then
	queryResults, err := getQueryResultForQueryString(APIstub, queryString)

	if err != nil {
		return shim.Error(err.Error())
	}
	
	return shim.Success(queryResults)
	
 }
 
 //Function to filter by Maintenance Date that are greater then
 func (s *SmartContract)filterByMaintenanceDate(APIstub shim.ChaincodeStubInterface, args []string) sc.Response{

	if len(args) < 1{
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	maintenanceDate,_ := strconv.Atoi(args[0]) //convert string to int

	queryString := fmt.Sprintf("{\"selector\":{\"Maintenance Date\": { \"$gt\": %d}}}", maintenanceDate) //using selector from couchdb and checking if dates is greater then
	queryResults, err := getQueryResultForQueryString(APIstub, queryString)

	if err != nil{
		return shim.Error(err.Error())
	}

	return shim.Success(queryResults)
 }

 //Function to filter by Building Id
 func (s *SmartContract)filterByBuildingId(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) < 1{
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	buildingId := args[0]

	queryString := fmt.Sprintf("{\"selector\":{\"Building Id\":\"%s\"}}", buildingId) //using selector for couchdb
	queryResults, err := getQueryResultForQueryString(APIstub, queryString)

	if err != nil{
		return shim.Error(err.Error())
	}

	return shim.Success(queryResults)
 }
 
 //Function to Init Ledger
 func (s *SmartContract) initLedger(APIstub shim.ChaincodeStubInterface) sc.Response {
	 filters := []HvacMaintenance{
		 HvacMaintenance{DateInstalled: 1542931200, MaintenanceDate: 1548201600, BuildingId: "500A", InstallerId : "0005679"},
		 HvacMaintenance{DateInstalled: 1542844800, MaintenanceDate: 1548201600, BuildingId: "500B", InstallerId : "0005678"},
		 HvacMaintenance{DateInstalled: 1542844800, MaintenanceDate: 1548301600, BuildingId: "400C", InstallerId : "0005689"},
		 HvacMaintenance{DateInstalled: 1542931200, MaintenanceDate: 1548301600, BuildingId: "500A", InstallerId : "0005679"},
	 }
 
	 i := 0
	 for i < len(filters) {
		 fmt.Println("i is ", i)
		 filtersAsBytes, _ := json.Marshal(filters[i])
		 APIstub.PutState("Maintenance"+strconv.Itoa(i), filtersAsBytes)
		 fmt.Println("Added", filters[i])
		 i = i + 1
	 }

	 return shim.Success(nil)
 }
 
 //Function to create new entry for Maintenance
 func (s *SmartContract) createNewMaintenance(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
 
	 if len(args) != 5 {
		 return shim.Error("Incorrect number of arguments. Expecting 5")
	 }
	 
	 //Install date and Maintenance date and converting to String
	 dateInstall,_ := strconv.Atoi(args[1])
	 maintenanceDate,_ := strconv.Atoi(args[2])

	 //json that will be entered 
	 var newFilterChange = HvacMaintenance{DateInstalled: dateInstall, MaintenanceDate: maintenanceDate, BuildingId: args[3], InstallerId: args[4]}
	 
	 //Converting to bytes
	 filterAsBytes, _ := json.Marshal(newFilterChange)
	 APIstub.PutState(args[0], filterAsBytes)
 
	 return shim.Success(nil)
 }
 
 //Function will display all Maintenanace using a starting key and a ending key
 func (s *SmartContract) showAllHvacMaintenance(APIstub shim.ChaincodeStubInterface) sc.Response {
 
	 startKey := "Maintenance0"
	 endKey := "Maintenance999"
 
	 resultsIterator, err := APIstub.GetStateByRange(startKey, endKey)
	 if err != nil {
		 return shim.Error(err.Error())
	 }
	 defer resultsIterator.Close()
 
	 // buffer is a JSON array containing QueryResults
	 var buffer bytes.Buffer
	 buffer.WriteString("[\n")
 
	 bArrayMemberAlreadyWritten := false
	 for resultsIterator.HasNext() {
		 queryResponse, err := resultsIterator.Next()
		 if err != nil {
			 return shim.Error(err.Error())
		 }
		 // Add a comma before array members, suppress it for the first array member
		 if bArrayMemberAlreadyWritten == true {
			 buffer.WriteString(",\n")
		 }
		 buffer.WriteString("{\"Key\":")
		 buffer.WriteString("\"")
		 buffer.WriteString(queryResponse.Key)
		 buffer.WriteString("\"")
 
		 buffer.WriteString(", \"Record\":")
		 // Record is a JSON object, so we write as-is
		 buffer.WriteString(string(queryResponse.Value))
		 buffer.WriteString("}")
		 bArrayMemberAlreadyWritten = true
	 }
	 buffer.WriteString("]\n")
 
	 fmt.Printf("- queryAllMaintenance:\n%s\n", buffer.String())
 
	 return shim.Success(buffer.Bytes())
 }

 //Function used by filtering functions
 func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	buffer, err := constructQueryResponseFromIterator(resultsIterator)
	if err != nil {
		return nil, err
	}

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}
//Function used by getQueryResultForQueryString for filtering functions
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) (*bytes.Buffer, error) {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return &buffer, nil
}
 
 // The main function is only relevant in unit test mode. Only included here for completeness.
 func main() {
 
	 // Create a new Smart Contract
	 err := shim.Start(new(SmartContract))
	 if err != nil {
		 fmt.Printf("Error creating new Smart Contract: %s", err)
	 }
 }
 