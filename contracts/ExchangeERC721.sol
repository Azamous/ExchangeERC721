pragma solidity ^0.6.12;

//import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC721 {
    function  ownerOf(uint256 tokenId) external view returns(address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ExchangeERC721 {

    struct SimpleExchange {
        uint token;
        bool state;
    }
    
    mapping(address => mapping(uint => SimpleExchange)) public currentExchanges;

    event ExchangeInit(uint indexed token1, uint indexed token2, address indexed tokenAddress);
    event ExchangeConfirmed(uint indexed token1, uint indexed token2, address indexed tokenAddress);
    event ExchangeDenied(uint indexed token1, uint indexed token2, address indexed tokenAddress);

    function InitExchangeRoom(
        uint myToken, 
        uint desiredToken,  
        address _to,
        address tokenAddress)
        external returns(bool)
    {
        ERC721 tokenInterface = ERC721(tokenAddress);
        require(msg.sender == tokenInterface.ownerOf(myToken), "Only for owner");
        require(_to == tokenInterface.ownerOf(desiredToken), "_to is not an owner of desired token");
        require(address(this) == tokenInterface.getApproved(myToken), "Approve for contract address first");

        currentExchanges[tokenAddress][myToken] = SimpleExchange(desiredToken, true);
        emit ExchangeInit(myToken, desiredToken, tokenAddress);
        return true;
    }

    function ConfirmExchange(
        uint myToken,
        uint desiredToken,
        address tokenAddress) external returns(bool)
    {
        require(currentExchanges[tokenAddress][desiredToken].token == myToken, "No exchange to such token");
        require(currentExchanges[tokenAddress][desiredToken].state, "Exchange was canceled");
        ERC721 tokenInterface = ERC721(tokenAddress);
        require( tokenInterface.ownerOf(myToken) == msg.sender, "Not an owner");
        require(address(this) == tokenInterface.getApproved(myToken) &&
                address(this) == tokenInterface.getApproved(desiredToken),
                 "Approve both tokens to the contract first");

        address desiredTokenOwner = tokenInterface.ownerOf(desiredToken);

        tokenInterface.transferFrom(desiredTokenOwner, msg.sender, desiredToken);
        tokenInterface.transferFrom(msg.sender, desiredTokenOwner, myToken);
        currentExchanges[tokenAddress][desiredToken].state = false;

        emit ExchangeConfirmed(desiredToken, myToken, tokenAddress);
        return true;
    }

    function DenyExchange(
        uint token1,
        uint token2,
        address tokenAddress) external returns(bool)
    {
        require(currentExchanges[tokenAddress][token1].token == token2 &&
                currentExchanges[tokenAddress][token1].state, "No such exchange exists");
         ERC721 tokenInterface = ERC721(tokenAddress);
         require(msg.sender == tokenInterface.ownerOf(token1) || msg.sender == tokenInterface.ownerOf(token2),
         "You must be owner of one of the tokens");
         _denyExchange(token1, token2, tokenAddress);
    }

    function GetSimpleExchangeForToken(uint tokenId, address tokenAddress) external view 
                returns(uint)
    {
        SimpleExchange memory exchange = currentExchanges[tokenAddress][tokenId];
        require(exchange.state, "No exchange currenty");
        return exchange.token;
    }

    function _denyExchange(
        uint token1,
        uint token2,
        address tokenAddress) private
    {
        currentExchanges[tokenAddress][token1].state = false;
        emit ExchangeDenied(token1, token2, tokenAddress);
    }
}