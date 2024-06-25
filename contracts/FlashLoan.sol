// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";
import "hardhat/console.sol";

contract FlashLoan {
    using SafeERC20 for IERC20;
    //UNISWAP Factory and Routing Addresses
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //SUSHI
    address private constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // Token Addresses
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function checkResult(uint _repay, uint _acquiredCoin) pure private returns(bool){
        return _acquiredCoin > _repay;
    }

    function getBalanceOfToken(address _address) public view returns(uint256){
        return IERC20(_address).balanceOf(address(this));
    }

    function placeTrade(address _fromToken, address _toToken, uint _amountIn, address factory, address router) private returns(uint){
        address pair = IUniswapV2Factory(factory).getPair(
            _fromToken,
            _toToken
        );
        require(pair != address(0), "Pool does not exist");
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(router).getAmountsOut(_amountIn, path)[1]; //1 because it approx gives us how much toToken we will get when we swap it with fromToken
        
        uint amountReceived = IUniswapV2Router01(router).swapExactTokensForTokens(
            _amountIn,
            amountRequired,
            path,
            address(this),
            deadline
        )[1];

        require(amountReceived > 0, "Transaction Abort");
        return amountReceived;
    }

    function initiateArbitrage(address _tokenBorrow, uint _amount) external{
        IERC20(WETH).safeApprove(address(UNISWAP_ROUTER), MAX_INT); //mere behalf pe UNISWAP_ROUTER spend kar sakta he WETH tokens(authority de rahe he) 
        IERC20(USDC).safeApprove(address(UNISWAP_ROUTER), MAX_INT);
        IERC20(LINK).safeApprove(address(UNISWAP_ROUTER), MAX_INT);

        IERC20(WETH).safeApprove(address(SUSHI_ROUTER), MAX_INT);
        IERC20(USDC).safeApprove(address(SUSHI_ROUTER), MAX_INT);
        IERC20(LINK).safeApprove(address(SUSHI_ROUTER), MAX_INT);
    
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(
            _tokenBorrow,
            WETH
        ); //GET LIQUIDITY POOL THAT DEALS WITH BOTH USDC AND WETH TOKENS
    
        require(pair != address(0), "Pool does not exist");

        address token0 = IUniswapV2Pair(pair).token0(); //WETH address 
        address token1 = IUniswapV2Pair(pair).token1(); //LINK address

        uint amount0Out = _tokenBorrow == token0 ? _amount: 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount: 0;

        bytes memory data = abi.encode(_tokenBorrow, _amount, msg.sender); //this variable indicates that the tokens transferred to our contract are to be used for flash loans
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); //transfer weth(from amount1out) to our contract(address(this))
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external{
        //msg.sender used: since pancakeCall is called by line 54 function so msg.sender = the contract address that calls the function = pair
        address token0 = IUniswapV2Pair(msg.sender).token0(); //WETH address 
        address token1 = IUniswapV2Pair(msg.sender).token1(); //LINK address

        //for security purposes we found out pair again and compared it with msg.sender
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "Pair does not match");
        require(_sender == address(this), "_sender does not match");

        (address tokenBorrow, uint amount, address account) = abi.decode(
            _data, (address, uint, address)
        );

        //fee calculation
        uint fee = ((amount*3)/997) + 1;

        uint repayAmount = amount + fee;

        uint loanAmount = _amount0 > 0 ? _amount0: _amount1; 
    
        //Cross arbitrage
        //placeTrade(token to exchange, token that is exchanged, amount of tokens exchanged)
        uint trade1Coin = placeTrade(USDC, LINK, loanAmount, UNISWAP_FACTORY, UNISWAP_ROUTER);
        uint trade2Coin = placeTrade(LINK, USDC, trade1Coin, SUSHI_FACTORY, SUSHI_ROUTER);

        bool result = checkResult(repayAmount, trade2Coin);
        require(result, "Arbitrage is not profitable");

        IERC20(USDC).transfer(account, trade2Coin - repayAmount);
        IERC20(tokenBorrow).transfer(pair, repayAmount);
    }
}
