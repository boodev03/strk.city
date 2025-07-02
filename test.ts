import fs from 'fs';
import { Account, cairo, Contract, json, RpcProvider } from 'starknet';

// connect provider
const provider = new RpcProvider({ nodeUrl: 'http://127.0.0.1:5050/rpc' });

const account0 = new Account(provider, "0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691", "0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9");
const compiledSierra = json.parse(
    fs.readFileSync('./target/dev/token_factory_ERC20.contract_class.json').toString('ascii')
);
// Deploy Test contract in Devnet
// ClassHash of the already declared contract
const testClassHash = '0x020e5a38053789fb4c30f3670ca8dcf9f32b0a88960763f25d54facab1d8a965';

const erc20 = new Contract(compiledSierra.abi, "0x5670e030cd8d970c970519dc340903a6dd7d30ee65f12c23d7bf7f3ef5182a8", provider);
erc20.connect(account0);

// Check balance - should be 20 NIT
console.log(`Calling Starknet for account balance...`);
const balanceInitial = await erc20.balanceOf(account0.address);
console.log('account0 has a balance of:', balanceInitial);

// Execute tx transfer of 1 tokens to account 1
console.log(`Invoke Tx - Transfer 1 tokens to erc20 contract...`);
const toTransferTk = cairo.uint256(1 * 10 ** 18);
const transferCall = erc20.populate('transfer', {
    recipient: '0x78662e7352d062084b0010068b99288486c2d8b914f6e2a55ce945f8792c8b1',
    amount: 1n * 10n ** 18n,
});
const { transaction_hash: transferTxHash } = await account0.execute(transferCall);
// Wait for the invoke transaction to be accepted on Starknet
console.log(`Waiting for Tx to be Accepted on Starknet - Transfer...`);
await provider.waitForTransaction(transferTxHash);

// Check balance after transfer - should be 19 NIT
console.log(`Calling Starknet for account balance...`);
const balanceAfterTransfer = await erc20.balanceOf(account0.address);
console.log('account0 has a balance of:', balanceAfterTransfer);
console.log('✅ Script completed.');