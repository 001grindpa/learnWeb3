// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract MagicNumbers {
    // VrfCoordinator mock contract constructor arguments hardcoded for mock
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK/ETH price argument
    int256 public MOCK_WEI_PRICE_UNIT_LINK = 4e15;

    uint256 public EthereumSepoliaChainId = 11155111;
    uint256 public LocalChainId = 31337;
}

contract HelperConfig is MagicNumbers, Script {
    // errors
    error HelperConfig__InvalidChainId();

    // custom datatypes
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address linkTokenAddress;
        address account;
    }

    // state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    // add sepolia config property to map by default in constructor
    constructor() {
        networkConfigs[EthereumSepoliaChainId] = getSepoliaEthConfig();
    }

    // declare functions that run and return the Raffle constructor arguments(activeNetworkConfig) during deployment based on the deploying chain
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 92177244555309113608266432348064208639916327090045183360735548218299095761676, // default 0
            linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xA1604a58dDB43831B77c2C82faBf6839153810a1
        });
    }

    function getAnvilEthconfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Deploy a mock version of the vrfCoordinator instance to anvil and other mock contracts
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock aVrfCoordinator =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PRICE_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        // assign a value to the localNetworkConfig when deployed on anvil using our mock CA as vrfCoordinator argument
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(aVrfCoordinator),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            linkTokenAddress: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // gotten from Base.sol contract
        });
        return localNetworkConfig;
    }

    // get networkConfig basedd on the deploying chainId
    /**
     * @notice - This function goes into the networkConfigs map to get a networkconfig data based on the deploying chain
     * @param - chainId -> this parameter is dynamic based on the deploying chain
     */
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LocalChainId) {
            return getAnvilEthconfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    // call the function that retrieves networkConfig
    /**
     * @notice - This function passes 'block.chainid'(dynamic value) into the function that retrieves networkConfig.
     * @return - It returns the required networkConfig dynamically.
     */
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
