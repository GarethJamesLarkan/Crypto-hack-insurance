// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/CHToken.sol";

import {console} from "forge-std/console.sol";

contract FundManagerTests is Test {

    FundManager managerInstance;
    Insurance insuranceInstance;
    CHToken token;
   
    address alice = vm.addr(3);
    address bob = vm.addr(4);
    address liquidityProvider1 = vm.addr(5);
    address liquidityProvider2 = vm.addr(6);


    function setUp() public {

        token = new CHToken();
        insuranceInstance = new Insurance(address(token));
        managerInstance = new FundManager(address(token), address(insuranceInstance));
    }

    function testAddInstallment() public {

        vm.startPrank(alice);

        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);    

        token.approve(address(managerInstance), 400000);

        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        //First payment and checks
        managerInstance.payPolicyInstallment(0, 2082);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        (uint256 id, uint256 value, uint256 installment, uint256 numOfInstallments, uint256 valueOfInstallments, uint256 holdingcompany, address owner) = insuranceInstance.policies(0); 

        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 1);
        assertEq(valueOfInstallments, 2082);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));

        //Second payment and checks
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        (, uint256 value2, uint256 installment2, uint256 numOfInstallments2, uint256 valueOfInstallments2, uint256 holdingcompany2, address owner2) = insuranceInstance.policies(0); 

        assertEq(value2, 250000);
        assertEq(installment2, 2082);
        assertEq(numOfInstallments2, 2);
        assertEq(valueOfInstallments2, 4164);
        assertEq(holdingcompany2, 0);
        assertEq(owner2, address(alice));

        vm.stopPrank();
        vm.startPrank(bob);

        token.mint(bob, 300000);
        token.approve(address(managerInstance), 400000);

        insuranceInstance.createPolicy(250000, 0);  
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 282082);
        assertEq(token.balanceOf(bob), 300000-2082);

    }

    function testPayInstallmentFailsWhenPolicyDoesNotExist() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);    

        token.approve(address(managerInstance), 400000);

        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        //First payment and checks
        vm.expectRevert("Incorrect payment amount");
        managerInstance.payPolicyInstallment(1, 2082);
        
    }

    function testAddInstallmentWith2LiquidityProviders() public {

        insuranceInstance.createHoldingCompany(50);

        token.mint(alice, 300000);
        token.mint(bob, 300000);

        vm.prank(alice);
        token.approve(address(managerInstance), 400000);

        vm.prank(bob);
        token.approve(address(managerInstance), 400000);

        vm.startPrank(alice);
        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.stopPrank();
        
        vm.startPrank(bob);
        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));
        assertEq(token.balanceOf(address(managerInstance)), 40000);
        vm.stopPrank();
        
        vm.startPrank(alice);
        insuranceInstance.createPolicy(250000, 0);  

        (uint256 id, uint256 value, uint256 installment, uint256 numOfInstallments, uint256 valueOfInstallments, uint256 holdingcompany, address owner) = insuranceInstance.policies(0); 
  
        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 0);
        assertEq(valueOfInstallments, 0);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));
        vm.stopPrank();
        
        vm.startPrank(bob);
        insuranceInstance.createPolicy(250000, 0); 

         (, uint256 value2, uint256 installment2, uint256 numOfInstallments2, uint256 valueOfInstallments2, uint256 holdingcompany2, address owner2) = insuranceInstance.policies(1); 
        assertEq(value2, 250000);
        assertEq(installment2, 2082);
        assertEq(numOfInstallments2, 0);
        assertEq(valueOfInstallments2, 0);
        assertEq(holdingcompany2, 0);
        assertEq(owner2, address(bob)); 
        vm.stopPrank();

        vm.startPrank(alice);

        //First payment and checks
        managerInstance.payPolicyInstallment(0, 2082);

        (, uint256 valueAfterInstallment, uint256 installmentAfterInstallment, uint256 numOfInstallmentsAfterInstallment, uint256 valueOfInstallmentsAfterInstallment,,) = insuranceInstance.policies(0); 
  
        assertEq(valueAfterInstallment, 250000);
        assertEq(installmentAfterInstallment, 2082);
        assertEq(numOfInstallmentsAfterInstallment, 1);
        assertEq(valueOfInstallmentsAfterInstallment, 2082);

        assertEq(token.balanceOf(alice), 278959);
        
        token.approve(address(managerInstance), 400000);  

        managerInstance.payPolicyInstallment(1, 2082);

        assertEq(token.balanceOf(bob), 278959);
        assertEq(token.balanceOf(address(managerInstance)), 40000);
        assertEq(token.balanceOf(alice), 282082);
        assertEq(token.balanceOf(bob), 300000-2082);



    }

    function testCreatingLiquidityProvider() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (,, uint256 valueOfLiquidity,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity, 20000);

    }

    function testAddLiquidity() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider(20000, address(managerInstance));

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (,, uint256 valueOfLiquidity,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity, 20000);

        managerInstance.addLiquidity(alice, 50000, address(managerInstance));

        assertEq(token.balanceOf(address(managerInstance)), 70000);
        assertEq(token.balanceOf(alice), 230000);

        (,, uint256 valueOfLiquidity2,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity2, 70000);
    }


}
