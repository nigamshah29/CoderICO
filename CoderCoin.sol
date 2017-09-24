pragma solidity ^0.4.4;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract CoderCoin is owned {

  // ERC20 State
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowances;
  uint256 public totalSupply;

  // Human State
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version;

  // Minter State
  address public centralMinter;

  // Backed By Ether State
  uint256 public buyPrice;
  uint256 public sellPrice;

  // Modifiers
  modifier onlyMinter {
    require(msg.sender == centralMinter);
    _;
  }

  // ERC20 Events
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // Constructor
  function CoderCoin(uint256 _initialAmount) {
    balanceOf[msg.sender] = _initialAmount;
    totalSupply = _initialAmount;
    name = "TestCoder";
    decimals = 18;
    symbol = "TCDR";
    version = "0.1";
  }

  // ERC20 Methods
  function balanceOf(address _address) constant returns (uint256 balance) {
    return balanceOf[_address];
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  /* Send coins */
  function transfer(address _to, uint256 _value) internal returns (bool success) {
    require(_to != 0x0);                                 //Prevent transfer to 0x0 address. Use burn() instead
    require(balanceOf[msg.sender] >= _value);            //Check if the sender has enough
    require(balanceOf[_to] + _value >= balanceOf[_to]);  //Check for overflows
    balanceOf[msg.sender] -= _value;                     //Subract tokens from sender
    balanceOf[_to] += _value;                            //Add the same to the recipient
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _owner, address _to, uint256 _value) returns (bool success) {
    require(balanceOf[_owner] >= _value);                //Check if owner has enough
    require(balanceOf[_to] + _value >= balanceOf[_to]);  //Check for overflows
    require(allowances[_owner][msg.sender] >= _value);
    balanceOf[_owner] -= _value;
    balanceOf[_to] += _value;
    allowances[_owner][msg.sender] -= _value;
    Transfer(_owner, _to, _value);
    return true;
  }

  // Minter Functions
  function mint(uint256 _amountToMint) onlyMinter {
    balanceOf[centralMinter] += _amountToMint;
    totalSupply += _amountToMint;
    Transfer(this, centralMinter, _amountToMint);
  }

  function transferMinter(address _newMinter) onlyMinter {
    centralMinter = _newMinter;
  }

  // Backed By Ether Methods
  // Must create the contract so that it has enough Ether to buy back ALL tokens on the market, or else the contract will be insolvent and users won't be able to sell their tokens

  /* Setting Token Price */
  function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyMinter {
    sellPrice = _newSellPrice;
    buyPrice = _newBuyPrice;
  }

  /* Buying tokens */
  function buy() payable returns (uint amount) {
    amount = msg.value / buyPrice;
    require(balanceOf[centralMinter] >= amount);           // Validate there are enough tokens minted
    balanceOf[centralMinter] -= amount;
    balanceOf[msg.sender] += amount;
    Transfer(centralMinter, msg.sender, amount);
    return amount;
  }

  /* Selling tokens */
  function sell(uint _amount) returns (uint revenue) {
    require(balanceOf[msg.sender] >= _amount);            // Validate sender has enough tokens to sell
    balanceOf[centralMinter] += _amount;
    balanceOf[msg.sender] -= _amount;
    revenue = _amount * sellPrice;
    if (!msg.sender.send(revenue)) {
      revert();
    } else {
      Transfer(msg.sender, centralMinter, _amount);
      return revenue;
    }
  }

}