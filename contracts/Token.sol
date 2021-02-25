// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.0;

/* taking ideas from FirstBlood token */
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

abstract contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public virtual returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        virtual
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/*  ERC 20 token */
contract StandardToken is Token {
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

contract NoaToken is StandardToken, SafeMath {
    // metadata
    string public constant name = "Noah Token";
    string public constant symbol = "NOH";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address payable public ethFundDeposit; // deposit address for ETH
    address public nohFundDeposit; // deposit address for NOH User Fund

    // crowdsale parameters
    bool public isFinalized; // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant nohFund = 500 * (10**6) * 10**decimals; // 500m NOH reserved for "stuff"
    uint256 public constant tokenExchangeRate = 6400; // 6400 NOH tokens per 1 ETH
    uint256 public constant tokenCreationCap = 1500 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin = 675 * (10**6) * 10**decimals;

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateNOH(address indexed _to, uint256 _value);

    // constructor
    constructor(
        address payable _ethFundDeposit,
        address _nohFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock
    ) {
        isFinalized = false; //controls pre through crowdsale state
        ethFundDeposit = _ethFundDeposit;
        nohFundDeposit = _nohFundDeposit;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        totalSupply = nohFund;
        balances[nohFundDeposit] = nohFund; // Deposit Noah share
        emit CreateNOH(nohFundDeposit, nohFund); // logs Noah fund
    }

    /// @dev Accepts ether and creates new NOH tokens.
    function createTokens() external payable {
        if (isFinalized) revert();
        if (block.number < fundingStartBlock) revert();
        if (block.number > fundingEndBlock) revert();
        if (msg.value == 0) revert();

        uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        // return money if something goes wrong
        if (tokenCreationCap < checkedSupply) revert(); // odd fractions won't be found

        totalSupply = checkedSupply;
        balances[msg.sender] += tokens; // safeAdd not needed; bad semantics to use here
        CreateNOH(msg.sender, tokens); // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
        if (isFinalized) revert();
        if (msg.sender != ethFundDeposit) revert(); // locks finalize to the ultimate ETH owner
        if (totalSupply < tokenCreationMin) revert(); // have to sell minimum to move to operational
        if (block.number <= fundingEndBlock && totalSupply != tokenCreationCap)
            revert();
        // move to operational
        isFinalized = true;
        if (!ethFundDeposit.send(address(this).balance)) revert(); // send the eth to Noah
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
        if (isFinalized) revert(); // prevents refund if operational
        if (block.number <= fundingEndBlock) revert(); // prevents refund until sale period is over
        if (totalSupply >= tokenCreationMin) revert(); // no refunds if we sold enough
        if (msg.sender == nohFundDeposit) revert(); // Noah not entitled to a refund
        uint256 nohVal = balances[msg.sender];
        if (nohVal == 0) revert();
        balances[msg.sender] = 0;
        totalSupply = safeSubtract(totalSupply, nohVal); // extra safe
        uint256 ethVal = nohVal / tokenExchangeRate; // should be safe; previous revert()s covers edges
        LogRefund(msg.sender, ethVal); // log it
        if (!payable(msg.sender).send(ethVal)) revert(); // if you're using a contract; make sure it works with .send gas limits
    }
}
