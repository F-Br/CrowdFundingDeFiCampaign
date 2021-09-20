var crowdFundingCampaign = artifacts.require("./CrowdFundCampaign.sol");

module.exports = function(deployer, accounts) {
    deployer.deploy(crowdFundingCampaign,
        "Test Campaign", true, "This is just a test of a campaign", "", "",
        10, 3, 1000);
};
