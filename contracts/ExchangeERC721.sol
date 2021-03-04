pragma solidity ^0.6.12;

//import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC721 {
    function  ownerOf(uint256 tokenId) external view returns(address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ExchangeERC721 {

    // struct SimpleExchange {
    //     uint token;
    //     bool state;
    // }
    
  //  mapping(address => mapping(uint => SimpleExchange)) public currentExchanges;
    mapping(address => mapping(uint => uint)) public currentExchanges;
    mapping(address => mapping(uint => bool)) public tokenState;

    event ExchangeInit(uint indexed token1, uint indexed token2, address indexed tokenAddress);
    event ExchangeConfirmed(uint indexed token1, uint indexed token2, address indexed tokenAddress);
    event ExchangeDenied(uint indexed token1, uint indexed token2, address indexed tokenAddress);

    modifier TokensCompare(uint token1, uint token2) {
        require(token1 != token2, "Exchange to the same token");
        _;
    }

    /* 
        Before initting, an owner of token1 has to approve contract address to use token
    */

    function InitExchangeRoom(
        uint myToken, 
        uint desiredToken,  
        address _to,
        address tokenAddress)
        external TokensCompare(myToken, desiredToken) returns(bool)
    {
        ERC721 tokenInterface = ERC721(tokenAddress);
        require(msg.sender == tokenInterface.ownerOf(myToken), "Only for owner");
        require(_to == tokenInterface.ownerOf(desiredToken), "_to is not an owner of desired token");
        require(address(this) == tokenInterface.getApproved(myToken), "Approve for contract address first");

        /* 
            Create an exchange between my token and another person's token
            Set an exchange for my token as true
        */

        currentExchanges[tokenAddress][myToken] = desiredToken;
        tokenState[tokenAddress][myToken] = true;
     //   tokenState[tokenAddress][desiredToken] = true;
        emit ExchangeInit(myToken, desiredToken, tokenAddress);
        return true;
    }


    /* 
        When an owner of token1 has set an exchange between two tokens, 
        owner of token2 has to:
        1) Approve contract address to use hit token
        2) Use ConfirmExchange function
    */

    function ConfirmExchange(
        uint myToken,
        uint desiredToken,
        address tokenAddress) external TokensCompare(myToken, desiredToken) returns(bool)
    {

        // Check if owner of desired token freezed his exchange
        require(tokenState[tokenAddress][desiredToken], "Exchange for token1 was denied");

     //   require(tokenState[tokenAddress][ myToken], "Exchange for token2 was denied");
        ERC721 tokenInterface = ERC721(tokenAddress);
        require( tokenInterface.ownerOf(myToken) == msg.sender, "Not an owner");
        require(address(this) == tokenInterface.getApproved(myToken) &&
                address(this) == tokenInterface.getApproved(desiredToken),
                 "Approve both tokens to the contract first");

        address desiredTokenOwner = tokenInterface.ownerOf(desiredToken);

        // Transfer tokens
        tokenInterface.transferFrom(desiredTokenOwner, msg.sender, desiredToken);
        tokenInterface.transferFrom(msg.sender, desiredTokenOwner, myToken);

        /*
             Destroy current exchangws for both tokens
             Set their exchange states as false as well
        */
        currentExchanges[tokenAddress][desiredToken] = desiredToken;
        currentExchanges[tokenAddress][myToken] = myToken;
        tokenState[tokenAddress][desiredToken] = false;
        tokenState[tokenAddress][myToken] = false;

        emit ExchangeConfirmed(desiredToken, myToken, tokenAddress);
        return true;
    }

    /* 
        Destroy current exchange between token1 and token2
        Allowade only for one of the owners
    */

    function DenyExchangeBetweenTokens(
        uint token1,
        uint token2,
        address tokenAddress) external TokensCompare(token1, token2) returns(bool)
    {
        require(currentExchanges[tokenAddress][token1] == token2, "No such exchange exists");
         ERC721 tokenInterface = ERC721(tokenAddress);
         require(msg.sender == tokenInterface.ownerOf(token1) || msg.sender == tokenInterface.ownerOf(token2),
         "You must be owner of one of the tokens");
         _denyExchangeBetweenTokens(token1, token2, tokenAddress);
    }

    function FreezeExchangeForMyToken(uint tokenId, address tokenAddress) external {
        ERC721 tokenInterface = ERC721(tokenAddress);
        require(msg.sender == tokenInterface.ownerOf(tokenId), "You are not an owner");
        tokenState[tokenAddress][tokenId] = false;
        
    }

    /*
        Get a current exchange which owner of tokenId has set 
    */

    function GetSimpleExchangeForToken(uint tokenId, address tokenAddress) external view 
                returns(uint)
    {
        require(tokenState[tokenAddress][tokenId], "No exchange currenty");
        return currentExchanges[tokenAddress][tokenId];
    }

    function _denyExchangeBetweenTokens(
        uint token1,
        uint token2,
        address tokenAddress) private
    {
        currentExchanges[tokenAddress][token1] = token1;
        tokenState[tokenAddress][token1] = false;
        emit ExchangeDenied(token1, token2, tokenAddress);
    }
}