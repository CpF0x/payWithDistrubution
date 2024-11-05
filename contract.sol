// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getBalance() external  view returns(uint256);
    function transfer(address to, uint256 value)  external  returns (bool);
    function allowance(address owner, address spender) external  returns (uint256);
}

contract PaymentDistribution {
    address public owner;
    address public USDTaddress ;
    uint256 public constant PAID_GROUP_PRICE = 10;
    IERC20 public usdt;
    
    uint256 public constant PAID_COURSE_PRICE = 5;
    uint256 public constant CHANNEL_SHARE = 30;
    
    struct Channel {
        address payable channelAddress;
        uint256 agentShare; // 渠道商给代理的分成百分比
    }
    
    mapping(address => Channel) public channels;
    
    event PaymentReceived(address payer, uint256 amount, string itemType);
    event DistributionMade(address channel, uint256 channelAmount, uint256 ownerAmount);
    event AllowanceChecked(address owner, uint allowance);

    constructor(address usdtaddress) {
        owner = msg.sender;
        USDTaddress = usdtaddress;
        usdt = IERC20(USDTaddress);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function getAllowance() public  returns(uint) {
         uint allowance = usdt.allowance(msg.sender, address(this));
         emit AllowanceChecked(msg.sender, allowance);
         return allowance;
    }

    
    function addChannel(address payable _channelAddress, uint256 _agentShare) public onlyOwner {
        require(_agentShare <= CHANNEL_SHARE, "Agent share cannot exceed channel share");
        channels[_channelAddress] = Channel(_channelAddress, _agentShare);
    }
    
    function payForGroup(address _channelAddress) public payable {
        require(msg.value == PAID_GROUP_PRICE, "Incorrect payment amount for paid group");
        uint256 OwnerAmout = (PAID_COURSE_PRICE * 70) / 100 ;
        uint256 ChannelAmount = (PAID_COURSE_PRICE * CHANNEL_SHARE) / 100;
        usdt.transferFrom(msg.sender, owner, OwnerAmout);
        usdt.transferFrom(msg.sender, _channelAddress, ChannelAmount);
    
    }
    
    function payForCourse(address _channelAddress) public payable {
        uint256 OwnerAmout = (PAID_COURSE_PRICE * 70) / 100 ;
        uint256 ChannelAmount = (PAID_COURSE_PRICE * CHANNEL_SHARE) / 100;
        usdt.transferFrom(msg.sender, owner, OwnerAmout);
        usdt.transferFrom(msg.sender, _channelAddress, ChannelAmount);
    }
    

    
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner).transfer(balance);
    }
    
    function getChannelInfo(address _channelAddress) public view returns (address, uint256) {
        Channel storage channel = channels[_channelAddress];
        return (channel.channelAddress, channel.agentShare);
    }
}
