// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract ECRYAToken is ERC20, ERC20Burnable, Ownable {
  mapping(address => bool) controllers;
  uint256 public constant maxSupply = 100_000_000_000e18;

  struct claimInfo{
    uint256 claimBalance;
    bool canClaim;
  }
  mapping(address => claimInfo) claimInfos;

  constructor(address _officail) ERC20("ECRYAToken", "ECRYA") {
    require(_officail != address(0));
    uint256 amount = maxSupply / 2; 
    _mint(_officail, amount);
  }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    uint256 supply = totalSupply();
    require(supply + amount <= maxSupply,"Out of max supply!");
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }else {
          super.burnFrom(account, amount);
      }
  }

  function addController(address controller) public onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) public onlyOwner {
    controllers[controller] = false;
  }

  function addClaimInfos(address[] calldata _claimAddrs,uint256[] calldata _amounts) public onlyOwner{
    require(_claimAddrs.length == _amounts.length,"addresses length must equal amounts length!");
    uint256 supply = totalSupply();
    for(uint32 i = 0;i < _claimAddrs.length;i++){
      supply += _amounts[i];
      require(supply <= maxSupply,"Out of max supply!");
      claimInfos[_claimAddrs[i]].claimBalance += _amounts[i];
      claimInfos[_claimAddrs[i]].canClaim = true;
    } 
  }

  function claim(uint256 _amount)public{
    require(claimInfos[msg.sender].canClaim,"This address can't claim!");
    require(claimInfos[msg.sender].claimBalance >= _amount,"Amount is bigger than claim balance!");
    uint256 supply = totalSupply();
    require(supply + _amount <= maxSupply,"Out of max supply!");
    _mint(msg.sender, _amount);
  }

  function getClaimInfo()public view returns(uint256 _claimBalance,bool _canClaim){
    return (claimInfos[msg.sender].claimBalance,claimInfos[msg.sender].canClaim);
  }
}