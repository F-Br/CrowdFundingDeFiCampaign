pragma solidity ^0.5.16;


contract CrowdFundCampaign {

    string public name;
    bool public usingDesc;
    string public description;
    string public link;
    string public linkHash;
    address payable public owner;

    Tier[] public tiers;
    uint public minTierValue;
    uint private currentNumTiers = 0;
    uint public numTiers;
    mapping(string => uint) public tierNameToIndex;

    address payable[] public pledgers;
    mapping(address => uint) public pledgedAmount;

    uint public pledges = 0;
    uint public target;
    uint public funding = 0;
    bool public closed = false;
    bool public fundingAccepted = false;
    uint public endDate = 0;


    struct Tier {
        string name;
        string description;
        uint cost;
        uint quantity;
        uint pledges;
    }



    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }



    constructor(string memory _name, bool _usingDesc, string memory _description, string memory _link, string memory _linkHash, uint _minTierValue, uint _numTiers, uint _target) public {
        // initialise core campaign parameters except tiers
        name = _name;
        usingDesc = _usingDesc;
        description = _description;
        link = _link;
        linkHash = _linkHash;
        owner = msg.sender;

        minTierValue = _minTierValue;
        numTiers = _numTiers;

        target = _target;
    }



    function addTier(string memory _name, string memory _description, uint _cost, uint _quantity) onlyOwner public {
        // adds a single tier
        // checks not exceeding number of tiers or falling below min tier value
        require(currentNumTiers < numTiers);
        require(_cost >= minTierValue);
        require(tierNameToIndex[_name] == 0); // require unique name
        Tier memory newTier = Tier({
                name: _name,
                description: _description,
                cost: _cost,
                quantity: _quantity,
                pledges: 0
            });
        tiers.push(newTier);
        currentNumTiers++;
        tierNameToIndex[_name] = currentNumTiers; // NOTE: this is supposed to be 1 higher than its actual index
    }

    function startCampaign() onlyOwner public {
        require(currentNumTiers == numTiers);
        require(!started());

        // TODO: add deposit to be made payable here by sender

        // where 30 is the set length for campaign to run for
        endDate = now + 30 days;
    }



    function started() public view returns (bool) {
        return (0 != endDate);
    }

    function ended() public view returns (bool) {
        return (now >= endDate);
    }

    function linkHashUnchanged() public pure returns (bool) {
        // TODO add way to check hash of link's website (the actual html page)
        return true;
    }

    function funded() public view returns (bool) {
        if (target > funding) {
            return false;
        }
        else {
            return true;
        }
    }



    function pledge(string memory _tierName) public payable {
        require(!ended());
        require(started());
        require(!closed);
        uint tierIndex = tierNameToIndex[_tierName];
        require(tierIndex != 0); // check tier exists
        require(tiers[tierIndex].cost == msg.value); // check correct amount pledged
        require(tiers[tierIndex].quantity > tiers[tierIndex].pledges);

        if (pledgedAmount[msg.sender] == 0) {
            pledgers.push(msg.sender);
        }

        pledgedAmount[msg.sender] += msg.value;
        pledges++;
        funding += msg.value;
        tiers[tierIndex].pledges++;
    }

    // owner return funds to pledgers
    function returnFundsToPledgersByOwner() onlyOwner public {
        require(ended());
        require(!closed);
        closed = true;
        fundingAccepted = false;

        for (uint i = 0; i < pledgers.length; i++) {
            address payable pledgeAddress = pledgers[i];
            pledgeAddress.transfer(pledgedAmount[pledgeAddress]); // may want to add if not then throw around it
        }

    }

    // pledgers return funds
    function returnFundsToPledgersByPledger() public {
        require(!closed);
        require(now > endDate + 10 days); // after 10 days this unlocks
        closed = true;
        fundingAccepted = false;

        for (uint i = 0; i < pledgers.length; i++) {
            address payable pledgeAddress = pledgers[i];
            pledgeAddress.transfer(pledgedAmount[pledgeAddress]); // may want to add if not then throw around it
        }
    }


    // owner receives funds
    function sendFundsToOwner() public {
        require(ended());
        require(!closed);
        require(funding >= target);
        require(linkHashUnchanged());
        closed = true;
        fundingAccepted = true;

        owner.transfer(funding);

    }
}
