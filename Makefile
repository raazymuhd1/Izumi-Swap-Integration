include .env

# TO EXECUTE EACH OF THESE COMMANDS, use "make exact-input-bsc" command in the terminal, adjust the command u want to execute
# ALL OF THESE COMMANDS ARE FOR TESTING CONTRACT
# testnet fork of bsc 
exact-input-bsc:; forge test --mt testExactInput --fork-url $(BSC_TESTNET_RPC) -vvvv
exact-output-bsc:; forge test --mt testExactOutput --fork-url $(BSC_TESTNET_RPC) -vvvv

# mainnet fork of bsc 
exact-input-bsc-mainnet:; forge test --mt test_exactInputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv
exact-output-bsc-mainnet:; forge test --mt test_exactOutputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv


# testnet fork of scroll 
exact-output-scroll:; forge test --mt test_exactOutputMultihop --fork-url $(SCROLL_TESTNET_RPC) -


# mainnet fork of bob
exact-input-bob:; forge test --mt test_exactInputBob --fork-url $(BOB_MAINNET_RPC) -vvvv
exact-output-bob:; forge test --mt test_exactOutputBob --fork-url $(BOB_MAINNET_RPC) -vvvv


# Deployments
deploy-bob:; forge script script/DeployTestSwap.s.sol:DeployMySwap --rpc-url $(BOB_MAINNET_RPC) --private-key $(PRIVATE_KEY)  --broadcast -vvvv --legacy

# verify contract on BOB
verify-bob:; forge verify-contract \
 --rpc-url https://rpc.gobob.xyz \
 --verifier blockscout \
 --verifier-url 'https://explorer-bob-mainnet-0.t.conduit.xyz/api/' \
 0x0B113Fba9514e4f9E9B7c6ff586f29aEd72d8cDa \
 src/TestSwap.sol:TestContractSwap


# test swap

test-swap:; cast send 0x0B113Fba9514e4f9E9B7c6ff586f29aEd72d8cDa \
 --rpc-url $(BOB_MAINNET_RPC) \
 "exactInput(address, address, uint128)" 0x4200000000000000000000000000000000000006 0x05D032ac25d322df992303dCa074EE7392C117b9 0001500000000000000 \
 --private-key $(PRIVATE_KEY) \
 --from 0xe8a00393a651A035fF0CD841c270d8a76529a4c2 \
