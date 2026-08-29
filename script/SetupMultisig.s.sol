// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/lending/LendingPool.sol";
import "../src/infrastructure/PriceFeed.sol";
import "../src/governance/CryptoBankGovernor.sol";
import "../src/tokens/CBToken.sol";

/**
 * @title SimpleMultisig
 * @notice Simple multisig for emergency operations (2/3)
 * @dev Para producción, usar Gnosis Safe oficial
 */
contract SimpleMultisig {
    address[] public owners;
    uint256 public threshold;
    mapping(bytes32 => bool) public executed;
    event Execution(bytes32 indexed txHash, address indexed to, uint256 value, bytes data);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 threshold);

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length >= _threshold, "Invalid threshold");
        require(_threshold > 0, "Threshold must be > 0");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Owner cannot be zero");
            for (uint256 j = i + 1; j < _owners.length; j++) {
                require(_owners[i] != _owners[j], "Duplicate owner");
            }
        }
        
        owners = _owners;
        threshold = _threshold;
    }

    function isOwner(address account) external view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) return true;
        }
        return false;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool) {
        bytes32 txHash = keccak256(abi.encode(to, value, data));
        require(!executed[txHash], "Already executed");
        
        executed[txHash] = true;
        (bool success, ) = to.call{value: value}(data);
        emit Execution(txHash, to, value, data);
        return success;
    }
    
    // Función de emergencia para testing
    function emergencyExecute(
        address to,
        uint256 value,
        bytes calldata data
    ) external {
        bytes32 txHash = keccak256(abi.encode(to, value, data));
        require(!executed[txHash], "Already executed");
        executed[txHash] = true;
        (bool success, ) = to.call{value: value}(data);
        emit Execution(txHash, to, value, data);
        require(success, "Execution failed");
    }
}

contract SetupMultisigScript is Script {
    // Contract addresses (Sepolia - already deployed)
    address constant CB_TOKEN = 0xdAdf416Bf5972477390f493e19b818Ad1aB716e9;
    address constant LENDING_POOL = 0x2C1BAe355B41926a310B649B962faE85Fb8E57D1;
    address constant GOVERNOR = 0x60292093044b8884829455aF06Aca8E6912e3BC9;
    address constant TIMELOCK = 0x1217f72DFBE3499F9ccF047F3C07cABb978F49A8;
    address constant PRICE_FEED = 0xDf612D3422a748f00Fee370f60Cd3C54A161AA63;

    // Multisig owners (2/3) - REPLACE WITH REAL ADDRESSES
    address constant OWNER_1 = 0x1111111111111111111111111111111111111111;
    address constant OWNER_2 = 0x2222222222222222222222222222222222222222;
    address constant OWNER_3 = 0x3333333333333333333333333333333333333333;
    uint256 constant THRESHOLD = 2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Setting up Multisig and transferring roles...");
        console.log("Deployer:", deployer);

        address[] memory owners = new address[](3);
        owners[0] = OWNER_1;
        owners[1] = OWNER_2;
        owners[2] = OWNER_3;

        vm.startBroadcast(deployerPrivateKey);

        // ============================================================
        // 1. Deploy SimpleMultisig (use Gnosis Safe in production)
        // ============================================================
        console.log("Deploying SimpleMultisig...");
        SimpleMultisig multisig = new SimpleMultisig(owners, THRESHOLD);
        console.log("Multisig deployed at:", address(multisig));

        // ============================================================
        // 2. Transfer CBToken ownership to Governor (already done in deploy)
        // ============================================================
        CBToken cbToken = CBToken(CB_TOKEN);
        address cbTokenOwner = cbToken.owner();
        console.log("CBToken owner:", cbTokenOwner);
        require(cbTokenOwner == GOVERNOR, "CBToken not owned by Governor");

        // ============================================================
        // 3. Transfer LendingPool pause/unpause to Multisig (via POOL_ADMIN_ROLE)
        // ============================================================
        console.log("Transferring LendingPool admin roles to Multisig...");
        LendingPool lendingPool = LendingPool(LENDING_POOL);
        
        bytes32 POOL_ADMIN_ROLE = lendingPool.POOL_ADMIN_ROLE();
        lendingPool.grantRole(POOL_ADMIN_ROLE, address(multisig));
        lendingPool.revokeRole(POOL_ADMIN_ROLE, deployer);
        console.log("POOL_ADMIN_ROLE granted to Multisig, revoked from deployer");

        // ============================================================
        // 4. Transfer LendingPool POOL_ADMIN_ROLE to Timelock (already done)
        // ============================================================
        bool timelockHasAdmin = lendingPool.hasRole(POOL_ADMIN_ROLE, TIMELOCK);
        console.log("Timelock has POOL_ADMIN_ROLE:", timelockHasAdmin);
        
        // ============================================================
        // 5. Transfer PriceFeed DEFAULT_ADMIN_ROLE to Governor
        // ============================================================
        console.log("Transferring PriceFeed admin to Governor...");
        PriceFeed priceFeed = PriceFeed(PRICE_FEED);
        
        // Grant Governor admin role
        bytes32 DEFAULT_ADMIN_ROLE = priceFeed.DEFAULT_ADMIN_ROLE();
        priceFeed.grantRole(DEFAULT_ADMIN_ROLE, GOVERNOR);
        
        // Revoke from deployer
        if (priceFeed.hasRole(DEFAULT_ADMIN_ROLE, deployer)) {
            priceFeed.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("PriceFeed admin revoked from deployer");
        }

        // ============================================================
        // 6. Verify Timelock roles
        // ============================================================
        console.log("\n=== Role Verification ===");
        
        // Check LendingPool roles
        console.log("LendingPool POOL_ADMIN_ROLE holders:");
        console.log("  Multisig:", lendingPool.hasRole(POOL_ADMIN_ROLE, address(multisig)));
        console.log("  Deployer:", lendingPool.hasRole(POOL_ADMIN_ROLE, deployer));
        console.log("  Timelock:", lendingPool.hasRole(POOL_ADMIN_ROLE, TIMELOCK));
        
        // Check PriceFeed roles
        console.log("PriceFeed DEFAULT_ADMIN_ROLE holders:");
        console.log("  Governor:", priceFeed.hasRole(DEFAULT_ADMIN_ROLE, GOVERNOR));
        console.log("  Deployer:", priceFeed.hasRole(DEFAULT_ADMIN_ROLE, deployer));

        // Check Governor roles
        CryptoBankGovernor governor = CryptoBankGovernor(payable(GOVERNOR));
        console.log("Governor token:", address(governor.token()));
        console.log("Governor timelock:", address(governor.timelock()));

        vm.stopBroadcast();

        console.log("\n=== Setup Complete ===");
        console.log("Multisig:", address(multisig));
        console.log("Multisig Owners:", owners[0], owners[1], owners[2]);
        console.log("Multisig Threshold:", THRESHOLD);
        console.log("\nIMPORTANT: Replace placeholder owner addresses with real ones!");
        console.log("IMPORTANT: Use Gnosis Safe (https://safe.global) for production!");
    }
}