pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract dividend {
    struct User {
        uint cursor; 
        uint amountBefore;
        uint amount;
        uint[] indexIn;
        mapping(uint => uint) amountIn;
        uint reward;
    }

    uint public index;
    address public admin;
    uint public quit;

    mapping(address => User) public stackers;
    mapping(uint => uint) public stackedByIndex;
    mapping(uint => uint) public dividendByIndex;

    IERC20 public token;
    
    constructor() {
        admin = msg.sender;
        //token = IERC20(0xeD1dC4D119c3Bd916970fB81F3095A2F55262204);
    }

    function addLiquidity() external payable{
        uint amount = msg.value;
        require(amount > 0, 'usage : dividend > 0.');
        require(msg.sender == admin, 'Admin only.');
        
        dividendByIndex[index] += amount;
        uint tmp = stackedByIndex[index];
        index += 1;
        stackedByIndex[index] += tmp; //- quit;
        quit = 0;
    }

    function getReward() public {
        User storage user = stackers[msg.sender];
        require(user.amount > 0, 'You are not stacking');
        require(user.cursor < index, 'You have to wait the next round');

        uint tmpAmount = user.amountBefore;
        uint reward;

        for(uint i = user.cursor; i < index; i++){
            tmpAmount += user.amountIn[i];
            reward += (tmpAmount * dividendByIndex[i]) / stackedByIndex[i];
        }

        user.cursor = index;
        user.amountBefore = tmpAmount;
        user.reward += reward;

        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send.");
    }

    function stack(uint amount) external payable{
        require(amount > 0, 'You have to stack more than 0.');
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(token.balanceOf(msg.sender) > amount, 'amount > balance.');

        User storage user = stackers[msg.sender];
        if(user.amount == 0)    user.cursor = index;
        user.amount += amount;
        user.indexIn.push(index);
        user.amountIn[index] += amount;

        stackedByIndex[index] += amount;

        //verif transfer erc 20
    }

    function unstack(uint amount) public {
        User storage user = stackers[msg.sender];

        require(amount > 0, 'Your stacking balance should be greater than 0.');
        require(user.amount > 0, 'You are not stacking');

        if(user.cursor != index){
            getReward();
            //quit += amount;
        }
        else{
            //stackedByIndex[index] -= amount;
            //quit += amount;
        }
        stackedByIndex[index] -= amount;
        user.amount -= amount;
        user.amountBefore -= amount;
    }

    function unstackAll() external {
        unstack(stackers[msg.sender].amount);
    }
}