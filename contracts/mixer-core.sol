// SPDX-License-Identifier: BSD-3-Clause-Clear


// TODO:
// support multi ERC-20 constructor, number of people in the pool

pragma solidity >=0.8.9 <0.9.0;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEncryptedERC20 {
    function transferFrom(address from, address to, bytes calldata encryptedAmount) external;
    function transfer(address to, bytes calldata encryptedAmount) external;
}

contract MixerCore {
    struct Recipient {
        euint32 encryptedRecipient;
        euint32 encryptedAmount;
    }
    Recipient[] public pool;
    address public erc20TokenAddress;
    IEncryptedERC20 public ERC20token;

    constructor(address _erc20TokenAddress) {
        erc20TokenAddress = _erc20TokenAddress;
        ERC20token = IEncryptedERC20(erc20TokenAddress);
    }

    // Deposits an encrypted amount of ERC-20 with an encrypted recipient.
    function deposit(bytes calldata encryptedRecipient, bytes calldata encryptedAmount) public {
        // Transfer ERC-20 to mixer
        ERC20token.transferFrom(msg.sender, address(this), encryptedAmount);
        pool.push(Recipient(TFHE.asEuint32(encryptedRecipient), TFHE.asEuint32(encryptedAmount)));
    }

    // Withdraws an encrypted amount of ERC-20.
    function withdraw(bytes calldata encryptedAmount) public {
        euint32 encryptedAddress = TFHE.asEuint32(addressTo32Bits(msg.sender));

        uint32 sum = 0;
        for (uint32 i = 0; i < pool.length; i++) {
            sum += i;
            ebool b = TFHE.eq(encryptedAddress, pool[i].encryptedRecipient);
            //euint32 amountToTransfer = TFHE.cmux(b, pool[i].encryptedAmount, 0);
            //pool[i].encryptedAmount = TFHE.sub(pool[i].encryptedAmount, amountToTransfer);
            // TFHE.req(b);
        }
        ERC20token.transfer(msg.sender, encryptedAmount);
    }

    // Function to convert an Ethereum address to a 32-bit representation
    function addressTo32Bits(address addr) public pure returns (uint32) {
        return uint32(uint160(addr));
    }
}