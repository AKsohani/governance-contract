// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title CharityGovernance
 * @dev Allows donors to vote on fund allocation proposals for charitable causes
 */
contract CharityGovernance {
    // Struct for charity proposal
    struct Proposal {
        uint256 id;
        address charityAddress;
        string description;
        uint256 fundsRequested;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // State variables
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public donorVotingPower;
    address public admin;
    uint256 public minDonationForVoting;
    uint256 public votingPeriod;

    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed charityAddress, uint256 fundsRequested);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }

    /**
     * @dev Constructor to initialize the governance contract
     * @param _minDonationForVoting Minimum donation required to gain voting rights
     * @param _votingPeriod Duration in seconds for which a proposal remains open for voting
     */
    constructor(uint256 _minDonationForVoting, uint256 _votingPeriod) {
        admin = msg.sender;
        minDonationForVoting = _minDonationForVoting;
        votingPeriod = _votingPeriod;
        proposalCount = 0;
    }

    /**
     * @dev Creates a new charity funding proposal
     * @param _charityAddress Address of the charity organization
     * @param _description Description of the proposal
     * @param _fundsRequested Amount of funds requested
     * @return proposalId ID of the newly created proposal
     */
    function createProposal(
        address _charityAddress,
        string memory _description,
        uint256 _fundsRequested
    ) external onlyAdmin returns (uint256) {
        require(_charityAddress != address(0), "Invalid charity address");
        require(_fundsRequested > 0, "Funds requested must be greater than 0");
        
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        
        newProposal.id = proposalCount;
        newProposal.charityAddress = _charityAddress;
        newProposal.description = _description;
        newProposal.fundsRequested = _fundsRequested;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.deadline = block.timestamp + votingPeriod;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCount, _charityAddress, _fundsRequested);
        
        return proposalCount;
    }

    /**
     * @dev Casts a vote on a proposal
     * @param _proposalId ID of the proposal
     * @param _support True for supporting the proposal, false for opposing
     */
    function castVote(uint256 _proposalId, bool _support) external validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(donorVotingPower[msg.sender] > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor += donorVotingPower[msg.sender];
        } else {
            proposal.votesAgainst += donorVotingPower[msg.sender];
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, donorVotingPower[msg.sender]);
    }
    
    /**
     * @dev Updates donor's voting power based on their donations
     * @param _donor Address of the donor
     * @param _donationAmount Amount donated
     * Note: This function would typically be called by the donation management contract
     */
    function updateVotingPower(address _donor, uint256 _donationAmount) external onlyAdmin {
        require(_donor != address(0), "Invalid donor address");
        require(_donationAmount >= minDonationForVoting, "Donation below minimum threshold");
        
        // Simple voting power calculation - can be adjusted based on requirements
        uint256 newVotingPower = _donationAmount / minDonationForVoting;
        donorVotingPower[_donor] += newVotingPower;
    }
}
