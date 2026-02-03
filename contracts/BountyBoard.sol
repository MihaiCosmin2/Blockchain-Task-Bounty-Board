// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUserReputation {
    function increaseReputation(address _user, uint _amount) external;
}

library TimeFunc {
    function daysToSeconds(uint _days) internal pure returns (uint) {
        return _days * 24 * 60 * 60;
    }
}

contract BountyBoard{

    using TimeFunc for uint;

    struct Task {
        uint id;
        address creator;    // Owner of task
        string title;
        string description;
        uint difficulty;    // Easy, Medium, Hard
        uint deadline;      // Time limit
        uint reward;        // Sum in ETH/wei
        bool isCompleted;   // State of solution
        address worker;     // Who solves
        string githubLink;  // The link's solution
    }

    // List of all tasks
    mapping(uint => Task) public tasks;
    mapping(uint => address[]) public taskApplicants;

    uint public taskCount = 0;
    IUserReputation public reputationContract;

    event TaskCreated(uint id, string title, uint reward);
    event TaskAssigned(uint id, address worker);
    event NewApplication(uint taskId, address aplicant);
    event WorkerAssigned(uint taskId, address worker);
//    event TaskCompleted(uint id, address worker);
    event TaskPaid(uint id, address worker, uint amount);
    event SolutionSubmitted(uint id, string link);

    // modifier care permite accesul doar creatorului taskului respectiv
    modifier onlyCreator(uint _id) {
        require(tasks[_id].creator == msg.sender, "Doar creatorul poate face asta");
        _;
    }

    // Modifier care permite accesul doar worker ului asignat
    modifier onlyWorker(uint _id) {
        require(tasks[_id].worker == msg.sender, "Doare worker-ul poate face asta.");
        _;
    }

    constructor(address _reputationContractAddress) {
        reputationContract = IUserReputation(_reputationContractAddress);
    }


    // Task creation function
    // When task is released, reward is blocked in contract
    function createTask(string memory _title, string memory _desc, uint _difficulty, uint _deadlineDays) public payable {
        require(msg.value > 0, "Reward must be greater than 0!");
//        require(_deadline > block.timestamp, "The deadline must be in the future!");

        uint durationInSeconds = TimeFunc.daysToSeconds(_deadlineDays);
        uint deadlineTimestamp = block.timestamp + durationInSeconds;

        taskCount++;
        tasks[taskCount] = Task(
            taskCount,
            msg.sender,
            _title,
            _desc,
            _difficulty,
            deadlineTimestamp,
            msg.value, // Retinem cat ETH a trimis userul
            false,
            address(0),
            ""
    );
        emit TaskCreated(taskCount, _title, msg.value);
    }

    function applyForTask(uint _id) public {
        Task storage t = tasks[_id];
        require(t.id != 0, "Task invalid");
        require(t.worker == address(0), "Task ul a fost deja atribuit!");
        require(msg.sender != t.creator, "Nu poti aplica la propriul task");

//        bool alreadyApplied = false;
//        for(uint i=0; i<taskApplicants[_id].length; i++) {
//            if(taskApplicants[_id][i] == msg.sender) {
//                alreadyApplied = true;
//                break;
//            }
//        }
//        require(!alreadyApplied, "Ai aplicat deja");

        taskApplicants[_id].push(msg.sender);
        emit NewApplication(_id, msg.sender);
    }

    function assignWorker(uint _id, address _worker) public onlyCreator(_id) {
        Task storage t = tasks[_id];
        require(t.worker == address(0), "Task deja atribuit!");

        t.worker = _worker;
        emit WorkerAssigned(_id, _worker);
    }

    function getApplicants(uint _id) public view returns (address[] memory) {
        return taskApplicants[_id];
    }

//    function acceptTask(uint _id) public {
//        Task storage t = tasks[_id];
//        require(t.id != 0, "Task-ul nu exista");
//        require(t.worker == address(0), "Task-ul este luat de altcineva");
//        require(msg.sender != t.creator, "Nu poti prelua propriul task.");
//        require(!t.isCompleted, "Task-ul e deja finalizat");
//
//        t.worker = msg.sender;
//        emit TaskAssigned(_id, msg.sender);
//    }

    function submitSolution(uint _id, string memory _githubLink) public onlyWorker(_id) {
        Task storage t = tasks[_id];
        t.githubLink = _githubLink;
        emit SolutionSubmitted(_id, _githubLink);
    }

    function approveTask(uint _id)  public onlyCreator(_id){
        Task storage t = tasks[_id];

        require(!t.isCompleted, "Task-ul a fost deja platit!");
        require(bytes(t.githubLink).length > 0, "Nu exista solutie trimisa.");

        t.isCompleted = true;

        payable(t.worker).transfer(t.reward);

        reputationContract.increaseReputation(t.worker, 10);

        emit TaskPaid(_id, t.worker, t.reward);
    }

    function convertDaysToSeconds(uint _days) public pure returns (uint) {
        return _days * 24 * 60 * 60;
    }

}
