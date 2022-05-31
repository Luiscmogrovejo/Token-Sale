// SPDX-License-Identifier: MIT

// Only use for solidity ^0.8.0
pragma solidity ^0.8.0;

// Import my tokens interface to interact with the tokns of the sale
// Token is an standard ERC20 token from Oppenzeppelin library V4
import './TrustGemsToken.sol';

// We start our Private Sale contract
contract PrivateSale {

    // Set admin for Admin only use
    address payable public admin;
    // Duration of sale in seconds
    uint256 public duration;
    // Set end blockstamp for sale
    uint256 public end;
    // Duration of vesting period
    uint256 public withdrawal;
    // Set a blockstamp for user withdrawal
    uint256 public canWithdraw;
    // This is the vault that recieves ERC payments
    address private vault;
    // Instance of the Sale token
    TrustGemsToken public token;
    // Number of tokens sold by contract
    uint256 public tokensSold;
    // Token price in cents 0.0X 
    uint public tokenPrice;
    // Instance of token that is used as payment
    IERC20 public ERC = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    // Number of total sale transactions
    uint256 public transactionCount;
    // Event emited after sale to inform user
    event Sell(address _buyer, uint256 _amount);
    // Event emited after sale to publish token amount and that user has withdrawed
    event LogWithdrawal(uint256 tokensWithdrawed, bool userHasWithdraw);
    // Returns the address of the added user
    event LogUserAdded(address user);
    // Returns the address of the removed user
    event LogUserRemoved(address user);
    // Returns amount of tokens sold
    event Sold(uint256 amount);
    // Sale event that sets how much tokens a user has bought and if he has withdrawn or not
    struct Sale {
        address investor;
        uint256 amount;
        bool tokensWithdrawn;
    }
    // Mapping to check if address bought tokens
    mapping(address => bool) public boughtTokens;
    // Mapping of the whitelist
    mapping(address => bool) public whitelisted;
    // Mapping that relates each sale to the address of buyer
    mapping(address => Sale) public sales;
    // Mapping that relates each sale to the address of buyer
    mapping(uint256 => Sale) public transaction;

    constructor(TrustGemsToken _token) {
        // Set standard parameters - They can also be inputed as the token address
        vault = 0xFB756D65C2E74281ACc6D05F13D249b4D9432063;
        tokenPrice = 3;
        token = _token;
        admin = payable(msg.sender);
        duration = 257400 ;
        withdrawal = 2160000;
    }
    
    // Function checks the whitelist for a user input 
    function checkWhitelist(address _checkAddress) public view returns(string memory) {
        // We store the result of the mapping - mapping will return a bool so must set variable tu boolean type
        bool userStatus = whitelisted[_checkAddress];
        // We define a string that will encode the result of boolean on the if statement
        string memory isWhitelisted;
        // We use if to check if the userStatus is True or False and return "YES" or "NO"
        if (userStatus == true) {isWhitelisted = "YES";
        } else { 
            isWhitelisted = "NO";
    }
    // We recieve the encoded result to process on console or frontend
    return isWhitelisted;
    }

    // Function that starts the sale can only be activated by Admin and Sale must be inactive
    function start() external onlyAdmin saleNotActive {
        // Passing the duration and adding it to the current blockstamp we get the end blockstamp of the contract
        end = block.timestamp + duration;
        // We add the vesting time after sale ends and get the blockstamp for the withdrawal
        canWithdraw = end + withdrawal ;
    }

    // Main function for buying tokens - Sale must be active
    function buyToken(uint _amountBUSD) public saleActive {
        // We get the address of buyer
        address from = msg.sender;
        // We check if he is whitelisted
        require(whitelisted[from], "user not whitelisted");
        // We make the convertion of the BUSD introduced to token amount in gei
        uint tokenAmount = (((_amountBUSD*10**18)/3)*100);
        // You need to buy at least 1 gei in tokens
        require(tokenAmount > 0, "Token amount 0");
        // The amount of tokens requires to be between 50 and 2000 usd
        require((tokenAmount >= 1666000000000000000000)  && (66666666666666666666667 >= tokenAmount), "Not between 50 or 2000 Busd");
        // The balance of tokens in sale must be bigger than the tokenAmount
        require(token.balanceOf(address(this)) >= tokenAmount, "More than available on contract");
        // User can only buy if he hasn't bought before or if he still has some rooom to get to max token amount
        require(boughtTokens[from] == false || sales[from].amount + tokenAmount <= 66666666666666666666667, "You only can buy 2000 Busd");
        // Transfer the ERC20 payment to the vault
        ERC.transferFrom(from, vault, (_amountBUSD*10**18));
        // Adds to get the amount of tokens sold for the whole sale
        tokensSold += tokenAmount;
        // We map the buyers address to his Sale information and fill the struct
        sales[from] = Sale(from, tokenAmount, false);
        // We map the number of the transaction to the sale information - This is just for Front end display if needed to map
        transaction[transactionCount] = Sale(from, tokenAmount, false);
        // Number of transactions made by contract
        transactionCount++;
        // We store that this user has purchased tokens
        boughtTokens[from] = true;
        // We emit a sell event that returns the buyers address and the token amount in token number(not gei number but full token number)
        emit Sell(from, (_amountBUSD));
    }

    // Function to withdraw the tokens after sale is done
    function withdrawTokens() external saleEnded userWithdraw {
        // Here we look for the sale struct of the buyer that wants to withdrall
        Sale storage sale = sales[msg.sender];
        // User must have bought an amount > 0 
        require(sale.amount > 0, "only investors");
        // User can only withdraw once
        require(sale.tokensWithdrawn == false, "tokens were already withdrawn");
        // Transfer the tokens to buyer
        require(token.transfer(sale.investor, sale.amount),"Tokens cannot be transfered");
        // We store that the user has withdraw after withdrawal
        sale.tokensWithdrawn = true;
        // We emit a withdrawal event to inform user of amount withdrawall and status        
        emit LogWithdrawal(sale.amount, sale.tokensWithdrawn);
    }

    // Function to finish sale and destroy contract for security reasons so after sale people can't interact with tokens
    function finishSale() public {
        // Only admin can call
        require(msg.sender == admin);
        // We get the tokens that were left inside of the sale contract
        uint256 amount = token.balanceOf(address(this));
        // Tokens get transfered to admin
        require(token.transfer(admin, amount), "Could'nt send tokens to admin");
        // Destroy the contract
        selfdestruct(payable(admin));
    }

    // Modifier of function that let's function know if Sale is active
    modifier saleActive() {
        // This requires that the blockstamp for end of sale is calculated
        require(
            end > 0 && block.timestamp < end,
            "Sale must be active"
        );
        // Every modifier needs to end in _; it needs run code after this
        _;
    }

    // Modifier of function that let's function know if Sale is inactive
    modifier saleNotActive() {
        // This checks if blockstamp for end of sale has been calculated
        require(end == 0, "Sale should not be active");
        _;
    }

    // Modifier of function that let's function know if Sale is Ended
    modifier saleEnded() {
        // This requires that the end blockstamp has been calculated
        // Also checks if sale still ongoing
        require(
            end > 0 && (block.timestamp >= end),
            "Sale must have ended"
        );
        // Every modifier needs to end in _; it needs run code after this
        _;
    }

    // Modifier that only let's admin call the function
    modifier onlyAdmin() {
        // Msg.sender must be the admin
        require(msg.sender == admin, "only admin");
        // Every modifier needs to end in _; it needs run code after this
        _;
    }

    // This modifier let's the contract know if user can withdraw tokens
    modifier userWithdraw() {
        // This requires that the blockstamp for withdrawal has been set
        // Also checks if is time to withdraw or not
        require(
            canWithdraw > 0 && (block.timestamp >= canWithdraw),
            "Sale must have ended"
        );
        // Every modifier needs to end in _; it needs run code after this
        _;
    }

    // Function that adds a user to the whitelist - Only can be called by admin
    function addUser(address user) external onlyAdmin {
        // We set the address of user to add to the whitelist
        whitelisted[user] = true;
        // We emit the address of the user whitelisted
        emit LogUserAdded(user);
    }

    // Function that removes an user from the whitelist - Only can be called by admin
    function removeUser(address user) external onlyAdmin {
        // We set the address of user to remove from the whitelist
        whitelisted[user] = false;
        // We emit the address of the user removed
        emit LogUserRemoved(user);
    }

    // Send a Batch of users to add - Only can be called by admin
    function addManyUsers(address[] memory users) external onlyAdmin {
        // Array of ussers must be lower than 10000
        require(users.length < 10000);
        // Now we do a forloop to one by one the addresses on the whitelist
        for (uint256 index = 0; index < users.length; index++) {
            // Inside this forloop we set the address of each user indivdually to be added to the whitelist
            whitelisted[users[index]] = true;
            // We emit an event with the array of addresses listed
            emit LogUserAdded(users[index]);
        }
    }
 
}
