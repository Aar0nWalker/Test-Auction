// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721A, Ownable {
    using ECDSA for bytes32;

    string private baseTokenURI;

    bool public publicSaleStarted;
    bool public prealeStarted;

    uint256 public publicSalePrice;
    uint256 public presalePrice;

    mapping(address => uint256) public NFTtracker;
    uint256 public NFTLimitPublic;
    uint256 public NFTLimitPresale;
    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);
    event PublicSaleMint(address mintTo, uint256 tokensCount);
    
    address founderAddress;

    uint256 public testValue;

    constructor(string memory baseURI, address _founderAddress) ERC721A("Collection", "NFT") {
        baseTokenURI = baseURI;
        founderAddress = _founderAddress;
    }
    
    //Settings

    function setPrices(uint256 _newPublicSalePrice, uint256 _newPresalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
        presalePrice = _newPresalePrice;
    }

    function setNFTLimits(uint256 _newLimitPublic, uint256 _newLimitPresale) public onlyOwner {
        NFTLimitPublic = _newLimitPublic;
        NFTLimitPresale = _newLimitPresale;
    }

    function setFounder(address _newFounder) public onlyOwner {
        founderAddress = _newFounder;
    }

    function setNFTHardcap(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
    }

    //Mint
    // _safeMint's second argument now takes in a quantity, not a tokenId.

    function PublicMint(uint256 quantity) external payable whenPublicSaleStarted {
    testValue = msg.value;
    require(totalSupply() + quantity <= maxNFTs, "Exceeded max NFTs amount");
    require(NFTtracker[msg.sender] + quantity <= NFTLimitPublic + NFTLimitPresale, "Minting would exceed wallet limit");
    require(publicSalePrice * quantity <= msg.value, "Fund amount is incorrect");
    _safeMint(msg.sender, quantity);
    NFTtracker[msg.sender] += quantity;
    }

    function PresaleMint(uint256 quantity, uint price, uint nounce, bytes memory signature) external payable whenPresaleStarted {
    require(NFTtracker[msg.sender] + quantity <= NFTLimitPresale, "Minting would exceed wallet limit");
    require(totalSupply() + quantity <= maxNFTs, "Exceeded max NFTs amount");
    require(presalePrice * quantity <= msg.value, "Fund amount is incorrect");
    require(verify(founderAddress, _msgSender(), quantity, price, nounce, signature) == true, "Presale must be minted from our website");
    _safeMint(msg.sender, quantity);
    NFTtracker[msg.sender] += quantity;
    }

    //Sales

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started yet");
        _;
    }

    modifier whenPresaleStarted() {
        require(publicSaleStarted, "Presale has not started yet");
        _;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function togglePresaleStarted() external onlyOwner {
        prealeStarted = !prealeStarted;
    }

    //WL Checker

    function getMessageHash(address _to, uint _amount, uint _price, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _price, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _price, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _price, _nounce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    //NFT Metadata Methods

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) 
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    // Withdraw

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(founderAddress, address(this).balance);
    }

    function withdrawPart(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(founderAddress, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }


}

