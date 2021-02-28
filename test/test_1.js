const Web3 = require('web3');
const web3 = new Web3(Web3.givenProvider || 'ws://localhost:8545');
const { expect } = require('chai');
const timeMachine = require('ganache-time-traveler');
const truffleAssert = require('truffle-assertions');

const ExchangeERC721 = artifacts.require('ExchangeERC721');
const Token = artifacts.require('DragonTokenERC721');

const name = "123";
const tokenAddress = "0x65107a51Ce51A41115B3CcC23BAc17C35a9F6eA8";

describe('Testing exchanging erc721 tokens', () => {
    let deployer;
    let user1, user2, user3, user4, user5;
    let exchangeInstance, tokenInstance;
    let snapshotId;

    before(async() => {
        [
            deployer,
            user1, user2, user3, user4, user5
        ] = await web3.eth.getAccounts();
        exchangeInstance = await ExchangeERC721.new({from: deployer});
        tokenInstance = await Token.at(tokenAddress);
    });

    describe('Simple exchanges tests', () => {
        beforeEach(async() => {
            // Create a snapshot
            const snapshot = await timeMachine.takeSnapshot();
            snapshotId = snapshot['result'];
           });
    
        afterEach(async() => await timeMachine.revertToSnapshot(snapshotId));

        it('Should exchange tokens between two addresses', async () => {
            // mint tokens
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user1});
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user2});
            // Init exchange
            await tokenInstance.approve(exchangeInstance.address, 0, {from: user1});
            await exchangeInstance.InitExchangeRoom(0, 1, user2, tokenAddress, {from: user1});
            // Confirm exchange
            await tokenInstance.approve(exchangeInstance.address, 1, {from: user2});
            await exchangeInstance.ConfirmExchange(1, 0, tokenAddress, {from: user2});
            //
            expect(await tokenInstance.ownerOf(0)).to.equal(user2);
            expect(await tokenInstance.ownerOf(1)).to.equal(user1);
        });

        it('Should show current exchange for token', async () => {
            // mint tokens
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user1});
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user2});
        // Init exchange
        await tokenInstance.approve(exchangeInstance.address, 0, {from: user1});
        await exchangeInstance.InitExchangeRoom(0, 1, user2, tokenAddress, {from: user1});
        // Get exchange
        expect(
            (await exchangeInstance.GetSimpleExchangeForToken(0, tokenAddress, {from: user2})).toNumber())
            .to.equal(1);
        });

        it('Should deny exchange', async () => {
             // mint tokens
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user1});
        await tokenInstance.CreateGreenWelschDragon(name, 0, {from: user2});
        // Init exchange
        await tokenInstance.approve(exchangeInstance.address, 0, {from: user1});
        await exchangeInstance.InitExchangeRoom(0, 1, user2, tokenAddress, {from: user1});
        // Deny exchange
        await exchangeInstance.DenyExchange(0, 1, tokenAddress, {from: user2});
        // Get exchange
        await truffleAssert.reverts(
            exchangeInstance.GetSimpleExchangeForToken(0, tokenAddress, {from: user2}),
            "No exchange currenty"
        );
        });
    });
});