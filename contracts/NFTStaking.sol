// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.8;

import "./ECRYAToken.sol";
import "./CryptagendeGame.sol";
import "./library/verify.sol";

contract NFTStaking is Ownable, IERC721Receiver {
  address public admin;
  uint256 public totalStaked;
  
  // struct to store a stake's token, owner, and timestamp.
  struct Stake {
    uint256 tokenId;
    address owner;
    uint64  timestamp;
  }

  // reference to the Block NFT contract
  CryptagendeGame nft;
  ECRYAToken token;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault; 

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event Unstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  constructor(CryptagendeGame _nft, ECRYAToken _token) { 
    nft = _nft;
    token = _token;
    admin = msg.sender;
  }

  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(nft.ownerOf(tokenId) == msg.sender, "Only owner can stake!");
      require(vault[tokenId].tokenId == 0, "already staked");
      nft.transferFrom(msg.sender, address(this), tokenId);
      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: tokenId,
        timestamp: uint64(block.timestamp)
      });
    }
  }

  function unstake(address account,uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "Only staker can unstake!");
      require(nft.ownerOf(tokenId) == address(this),"This token is not owned by contract.");
      delete vault[tokenId];
      nft.transferFrom(address(this), account, tokenId);
      emit Unstaked(account, tokenId, block.timestamp);
    }
  }

  function claim(uint256 amount,bytes calldata signature) external {
      if (amount > 0) {
        if(SignatureVerifier.verifySignature(signature,admin,amount)){
          token.mint(msg.sender, amount);
          emit Claimed(msg.sender, amount);
        }
    }
  }

  // should never be used inside of transaction because of gas fee
  function stakedBalance(address account) public view returns (uint256) {
      uint256 balance = 0;
      uint256 supply = nft.totalSupply();
      for(uint i = 1; i <= supply; i++) {
        if (vault[i].owner == account) {
          balance += 1;
        }
      }
    return balance;
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {
    uint256 supply = nft.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
  }
}

