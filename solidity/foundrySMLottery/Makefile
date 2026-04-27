-include .env

.PHONY: all test deploy # reserve these words

FAKE_KEY:="825e33bb8a49134037ba6811a68ac94847de4b1ea18c07beb08e65f75ff52fa0"

check:; echo $(FAKE_KEY)

build:; forge build

deploy-sepolia:; @forge script script/DeployRaffle.s.sol --rpc-url $(SEPOLIA_RPC_URL) --broadcast --account secretKey --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

test:; @forge test

install:; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge install foundry-rs/forge-std@v1.8.2 && forge install transmissions11/solmate@v6

# deployed ca on sepolia 0xF572771c0E3221dF6fb718BAD6D1659868d2414c
# new one 0xCe96A62Ea4abAA906801adFe34fFc88303067BFe