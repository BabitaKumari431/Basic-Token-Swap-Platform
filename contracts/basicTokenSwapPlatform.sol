// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwapPlatform is Ownable {
    // Mapping to store token addresses that are accepted for swapping
    mapping(address => bool) public acceptedTokens;

    // Event emitted when a swap occurs
    event TokensSwapped(
        address indexed user,
        address indexed tokenIn,
        uint256 amountIn,
        address indexed tokenOut,
        uint256 amountOut
    );

    // FIX: Pass the initial owner to the Ownable constructor
    constructor(address initialOwner) Ownable(initialOwner) {
        // Any additional setup for TokenSwapPlatform
    }

    /**
     * @dev Adds a token to the list of accepted tokens for swapping.
     * Only the contract owner can call this function.
     * @param _tokenAddress The address of the ERC20 token to add.
     */
    function addAcceptedToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        acceptedTokens[_tokenAddress] = true;
    }

    /**
     * @dev Removes a token from the list of accepted tokens.
     * Only the contract owner can call this function.
     * @param _tokenAddress The address of the ERC20 token to remove.
     */
    function removeAcceptedToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        acceptedTokens[_tokenAddress] = false;
    }

    /**
     * @dev Swaps one accepted token for another.
     * The user must approve this contract to spend `amountIn` of `_tokenIn`.
     * This contract acts as a simple intermediary for a fixed swap ratio (for demonstration).
     * In a real-world scenario, this would involve a price oracle or liquidity pools.
     * @param _tokenIn The address of the token the user is sending.
     * @param _amountIn The amount of `_tokenIn` the user is sending.
     * @param _tokenOut The address of the token the user wants to receive.
     * @param _minAmountOut The minimum amount of `_tokenOut` the user expects to receive.
     * Used to prevent front-running or slippage.
     */
    function swapTokens(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut
    ) public {
        require(acceptedTokens[_tokenIn], "TokenIn not an accepted token");
        require(acceptedTokens[_tokenOut], "TokenOut not an accepted token");
        require(_tokenIn != _tokenOut, "Cannot swap the same token");
        require(_amountIn > 0, "AmountIn must be greater than zero");

        IERC20 tokenIn = IERC20(_tokenIn);
        IERC20 tokenOut = IERC20(_tokenOut);

        // Transfer _tokenIn from the user to this contract
        bool success = tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        require(success, "TokenIn transfer failed");

        // --- DEMONSTRATION SWAP LOGIC ---
        // In a real application, this would involve a complex pricing mechanism
        // (e.g., AMM like Uniswap, oracle-based pricing, etc.).
        // For this basic example, let's assume a simple 1:1 swap for illustration
        // This means the contract needs to hold enough _tokenOut.
        uint256 amountOut = _amountIn; // Simple 1:1 ratio for demonstration

        // Check if the contract has enough _tokenOut
        require(tokenOut.balanceOf(address(this)) >= amountOut, "Not enough tokenOut in contract");
        require(amountOut >= _minAmountOut, "Slippage protection: amountOut too low");

        // Transfer _tokenOut from this contract to the user
        success = tokenOut.transfer(msg.sender, amountOut);
        require(success, "TokenOut transfer failed");

        emit TokensSwapped(msg.sender, _tokenIn, _amountIn, _tokenOut, amountOut);
    }

    /**
     * @dev Allows the owner to withdraw any accidentally sent ERC20 tokens.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAccidentallySentTokens(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "Withdrawal failed");
    }
}
