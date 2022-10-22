// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/MockUSDC.sol";

import {console} from "forge-std/console.sol";

contract InsuranceTests is Test {

    Insurance insuranceInstance;
    FundManager managerInstance;

    MockUSDC token;
   
    address alice = vm.addr(3);

    function setUp() public {
        
        token = new MockUSDC();
        insuranceInstance = new Insurance(address(token));
        managerInstance = new FundManager(address(token), address(insuranceInstance));

    }

    function testCreateHoldingCompany() public {

        insuranceInstance.createHoldingCompany(50);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 1);

        (uint256 id, uint256 safetyRating) = insuranceInstance.holdingCompanies(0); 
        assertEq(id, 0);
        assertEq(safetyRating, 50);

        insuranceInstance.createHoldingCompany(80);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 2);

        (id, safetyRating) = insuranceInstance.holdingCompanies(1); 
        assertEq(id, 1);
        assertEq(safetyRating, 80);
      
    }

    function testCalculatePolicyInstallments() public {
        insuranceInstance.createHoldingCompany(50);
        uint256 val = insuranceInstance.calculatePolicyInstallments(250000, 0);
        assertEq(val, 2082);

        insuranceInstance.createHoldingCompany(95);
        uint256 val2 = insuranceInstance.calculatePolicyInstallments(500000, 1);
        assertEq(val2, 2915);
    }

    function testCreatePolicy() public {

        vm.startPrank(alice);
        
        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);

        (uint256 id, uint256 value, uint256 installment, uint256 numOfInstallments, uint256 valueOfInstallments, uint256 holdingcompany,,address owner) = insuranceInstance.policies(0); 
        
        assertEq(insuranceInstance.numberOfPolicies(), 1);
        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 0);
        assertEq(numOfInstallments, 0);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));

    }
}
