//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestAuction is IERC721Receiver{

    struct Assert {
        uint id;
        address owner;
        string name;
        uint startPrice;
        uint soldPrice;
        address buyer;
        mapping(address => uint) offeredPrices;
        address NFTAddress;
        uint TokenId;
        bool sold;
        bool removed;
    }
    uint lastAssertId;
    mapping(uint => Assert) asserts;

    function onERC721Received( address , address , uint256 , bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier onlyAssertOwner(uint AssertId) {
        require (msg.sender == asserts[AssertId].owner, "you are not owner");
        _;
    }

    modifier onlyActiveAssert(uint AssertId) {
        require (!asserts[AssertId].sold && !asserts[AssertId].removed, "purchased asset");
        _;
    }

    modifier onlyExistingAssert(uint AssertId) {
        require (AssertId <= lastAssertId, "invalid asset");
        _;
    }

    function addAssert(address _NFTAddress, uint256 _TokenID, string memory Name, uint Price) public {
        IERC721(_NFTAddress).safeTransferFrom(msg.sender, address(this), _TokenID);
        lastAssertId++;

        asserts[lastAssertId].id = lastAssertId;
        asserts[lastAssertId].owner = msg.sender;
        asserts[lastAssertId].name = Name;
        asserts[lastAssertId].startPrice = Price;
        asserts[lastAssertId].NFTAddress = _NFTAddress;
        asserts[lastAssertId].TokenId = _TokenID;
    }

    function removeAssert(uint AssertId) external onlyAssertOwner(AssertId) onlyExistingAssert(AssertId){
        address _NFTAddress = asserts[AssertId].NFTAddress;
        uint _TokenID = asserts[AssertId].TokenId;
        IERC721(_NFTAddress).approve(msg.sender, _TokenID);
        IERC721(_NFTAddress).safeTransferFrom(address(this), msg.sender, _TokenID);
        asserts[AssertId].removed = true;
    }

    function buyAssert(uint AssertId) external payable onlyActiveAssert(AssertId) onlyExistingAssert(AssertId){
        address _buyer = asserts[AssertId].buyer;
        uint _price = asserts[AssertId].startPrice;
        require(_buyer == address(0), "the asset has already been purchased");
        require(msg.value == _price, "Wrong value");
        address _NFTAddress = asserts[AssertId].NFTAddress;
        uint _TokenID = asserts[AssertId].TokenId;
        IERC721(_NFTAddress).approve(msg.sender, _TokenID);
        IERC721(_NFTAddress).safeTransferFrom(address(this), msg.sender, _TokenID);
        asserts[AssertId].buyer = msg.sender;
        asserts[AssertId].soldPrice = _price;
        asserts[AssertId].sold = true;
    }

    function offerPrice(uint AssertId, uint _price) external onlyExistingAssert(AssertId){
        asserts[AssertId].offeredPrices[msg.sender] = _price;
    }

    function sellForTheOfferedPrice(uint AssertId, address buyer) external onlyAssertOwner(AssertId) onlyExistingAssert(AssertId){
        asserts[AssertId].buyer = buyer;
    }

    function cancelSellForTheOfferedPrice(uint AssertId) external onlyAssertOwner(AssertId) onlyExistingAssert(AssertId){
        asserts[AssertId].buyer = address(0);
    }

    function buyAssertForTheOfferedPrice(uint AssertId) external payable onlyActiveAssert(AssertId) onlyExistingAssert(AssertId) {
        address _buyer = asserts[AssertId].buyer;
        uint _price = asserts[AssertId].offeredPrices[_buyer];
        require(_buyer == msg.sender, "the asset has already been purchased");
        require(msg.value == _price, "Wrong value");
        address _NFTAddress = asserts[AssertId].NFTAddress;
        uint _TokenID = asserts[AssertId].TokenId;
        IERC721(_NFTAddress).approve(msg.sender, _TokenID);
        IERC721(_NFTAddress).safeTransferFrom(address(this), msg.sender, _TokenID);
        asserts[AssertId].soldPrice = _price;
        asserts[AssertId].sold = true;
    }

    function buyerData(uint AssertId) external view returns(address) {
        return(asserts[AssertId].buyer);
    }

    function assertData(uint AssertId) external view 
    returns(uint id, address owner, string memory name, uint startPrice, uint soldPrice, address buyer, address NFTAddress, uint TokenId, bool sold, bool removed) {
        uint _assertId = AssertId;
        return (asserts[_assertId].id, asserts[_assertId].owner, asserts[_assertId].name,
        asserts[_assertId].startPrice, asserts[_assertId].soldPrice, asserts[_assertId].buyer,
        asserts[_assertId].NFTAddress, asserts[_assertId].TokenId, asserts[_assertId].sold, asserts[_assertId].removed);
    }

    function offeredPriceData(uint AssertId, address buyer) external view returns(uint offeredPrice) {
        return (asserts[AssertId].offeredPrices[buyer]);
        }


}