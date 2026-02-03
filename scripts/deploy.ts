import { ethers } from "hardhat";

async function main() {

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const UserReputation = await ethers.getContractFactory("UserReputation");
    const userReputation = await UserReputation.deploy();
    await userReputation.waitForDeployment();
    const reputationAddress = await userReputation.getAddress();
    console.log("UserReputation deployed to:", reputationAddress);

    const BountyBoard = await ethers.getContractFactory("BountyBoard");
    const bountyBoard = await BountyBoard.deploy(reputationAddress);
    await bountyBoard.waitForDeployment();
    const bountyBoardAddress = await bountyBoard.getAddress();
    console.log("BountyBoard deployed to:", bountyBoardAddress);

    const tx = await userReputation.setBountyBoard(bountyBoardAddress);
    await tx.wait();
    console.log("UserReputation linked to BountyBoard successfully!");

    console.log("REPUTATION_ADDRESS:", reputationAddress);
    console.log("CONTRACT_ADDRESS", bountyBoardAddress);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
