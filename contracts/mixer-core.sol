// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.9 <0.9.0;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

contract MixerCore {
    struct Recipient {
        euint32 encryptedRecipient;
        euint32 encryptedAmount;
    }

    Recipient[] public pool;
    ebool public test;
    euint32 public test2;


    // Deposits an encrypted amount of ERC-20 with an encrypted recipient.
    function deposit(bytes calldata encryptedRecipient, bytes calldata encryptedAmount) public {
        pool.push(Recipient(TFHE.asEuint32(encryptedRecipient), TFHE.asEuint32(encryptedAmount)));
    }

    // Withdraws an encrypted amount of ERC-20.
    function withdraw(bytes calldata encryptedAmount) public {
        euint32 encryptedAddress = TFHE.asEuint32(addressTo32Bits(msg.sender));
        test2 = encryptedAddress;

        uint32 sum = 0;
        for (uint32 i = 0; i < pool.length; i++) {
            sum += i;
            ebool b = TFHE.eq(encryptedAddress, pool[i].encryptedRecipient);
            TFHE.req(b);
            test = b;
        }
    }

    // Function to convert an Ethereum address to a 32-bit representation
    function addressTo32Bits(address addr) public pure returns (uint32) {
        return uint32(uint160(addr));
    }
}