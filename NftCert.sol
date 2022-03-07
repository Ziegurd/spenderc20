// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import "@nibbstack/erc721/src/contracts/tokens/nf-token.sol";
// import "@nibbstack/erc721/src/contracts/tokens/nf-token-enumerable.sol";
// import "@nibbstack/erc721/src/contracts/ownership/ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Spendable} from "./AriaToken.sol";

// contract NftCert is NFTokenEnumerable, Ownable {
contract NftCert is ERC721Enumerable, Ownable {
  using Strings for uint256;

  /// @notice The currency to create new certificates
  ERC20Spendable _mintingCurrency;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 1;
  uint256 public maxSupply = 50;
  uint256 public maxMintAmount = 4;
  bool public paused = false;
  bool public revealed = true;
  string public notRevealedUri;
  /// @dev The serial number of the next certificate to create
  uint256 nextCertificateId = 1;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  /**
    * @notice The currency (ERC20) to create certificates
    * @return The currency (ERC20) to create certificates
    */
  function mintingCurrency() external view returns (ERC20Spendable) {
      return _mintingCurrency;
  }

  /**
    * @notice Set new ERC20 currency to create certificates
    * @param newMintingCurrency The new currency
    */
  function setMintingCurrency(ERC20Spendable newMintingCurrency) onlyOwner external {
      _mintingCurrency = newMintingCurrency;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public {
    _mintAmount = 1;
    // uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    // require(supply + _mintAmount <= maxSupply);
    require(nextCertificateId < maxSupply);

    // Take payment for this service
    _mintingCurrency.spend(msg.sender, cost * _mintAmount);

    // Create the certificate
    uint256 newCertificateId = nextCertificateId;
    _mint(msg.sender, newCertificateId);
    nextCertificateId = nextCertificateId + 1;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}