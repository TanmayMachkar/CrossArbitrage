//formatUnits -> convert wei to ether (18 decimals to ether)
//-> used to convert value returned from smart contract to ether

//parseUnits -> convert ether to wei
//-> used to convert value from ether to wei to pass as parameter to a function call (since smart contract deals with wei)

const { expect, assert } = require('chai');
const { ethers } = require('hardhat');
const { fundContract } = require('../utils/utilities');

const {
  abi,
} = require('../artifacts/contracts/interfaces/IERC20.sol/IERC20.json');

const provider = waffle.provider;

describe('FlashLoan Contract',() => {
  let FLASHLOAN,
  BORROW_AMOUNT,
  FUND_AMOUNT,
  initialFundingHuman,
  txArbitrage;

  const DECIMALS = 6; //decimal for usdc is 6

  const USDC_WHALE = "0xcffad3200574698b78f32232aa9d63eabd290703";
  const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
  const LINK = '0x514910771AF9Ca656af840dff83E8264EcF986CA';

  const usdcInstance = new ethers.Contract(USDC, abi, provider);

  beforeEach(async() => {
    const whale_balance = await provider.getBalance(USDC_WHALE);
    expect(whale_balance).not.equal('0');
  
    //deploy smart contract
    const FlashLoan = await ethers.getContractFactory('FlashLoan');
    FLASHLOAN = await FlashLoan.deploy();
    await FLASHLOAN.deployed();

    const borrowAmountHuman = '1';
    BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmountHuman, DECIMALS); //convert ether to wei
    initialFundingHuman = '100';
    FUND_AMOUNT = ethers.utils.parseUnits(initialFundingHuman, DECIMALS);

    await fundContract(
      usdcInstance,
      USDC_WHALE,
      FLASHLOAN.address,
      initialFundingHuman,
      DECIMALS
    )
  })
  describe('Arbitrage Execution', () => {
    it('ensures the contract is funded', async() => {
      const flashLoanBalance = await FLASHLOAN.getBalanceOfToken(USDC);
      const flashLoanBalanceHuman = ethers.utils.formatUnits( //convert wei to ether
        flashLoanBalance,
        DECIMALS
      )
      expect(Number(flashLoanBalanceHuman)).equal(Number(initialFundingHuman))
    })

    it('execute the arbitrage', async() => {
      txArbitrage = await FLASHLOAN.initiateArbitrage(
        USDC,
        BORROW_AMOUNT
      )
      assert(txArbitrage)

      //Print all 3 balances
      const contractBalanceUSDC = await FLASHLOAN.getBalanceOfToken(USDC);
      const formattedBalUSDC = Number(
        ethers.utils.formatUnits(contractBalanceUSDC, DECIMALS)
      );
      console.log("Balance of USDC: " + formattedBalUSDC);

      const contractBalanceLINK = await FLASHLOAN.getBalanceOfToken(LINK);
      const formattedBalLINK = Number(
        ethers.utils.formatUnits(contractBalanceLINK, DECIMALS)
      );
      console.log("Balance of LINK: " + formattedBalLINK);
    })
  })
})