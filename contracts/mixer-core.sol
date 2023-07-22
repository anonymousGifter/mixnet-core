    // SPDX-License-Identifier: BSD-3-Clause-Clear

    pragma solidity >=0.8.9 <0.9.0;

    import "fhevm/abstracts/EIP712WithModifier.sol";
    import "fhevm/lib/TFHE.sol";

    interface IEncryptedERC20 {
        function transferFrom(address from, address to, bytes calldata encryptedAmount) external;
        function transfer(address to, euint32 encryptedAmount) external;
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
        function withdraw() public {
            euint32 encryptedAddress = TFHE.asEuint32(addressTo32Bits(msg.sender));
            euint32 sum = TFHE.asEuint32(0);
            for (uint32 i = 0; i < pool.length; i++) {
                // Note: Hacky temporary fix for faulty cmux type issue
                ebool b = TFHE.eq(encryptedAddress, pool[i].encryptedRecipient);
                euint8 b2 = TFHE.asEuint8(b);
                euint32 b3 = TFHE.asEuint32(b2);
                ebool b4 = ebool.wrap(euint32.unwrap(b3));
                // Amount to transfer is 0 or the valid amount
                euint32 amountToTransfer = TFHE.cmux(b4, pool[i].encryptedAmount, TFHE.asEuint32(0));
                // Add the amount to sum
                sum = TFHE.add(sum, amountToTransfer);
                // We reduce by the amount to avoid double spending
                pool[i].encryptedAmount = TFHE.sub(pool[i].encryptedAmount, amountToTransfer);
            }
            // Fail if sum is 0
            TFHE.req(TFHE.ne(sum, 0));
            ERC20token.transfer(msg.sender, sum);
        }

        // Function to convert an Ethereum address to a 32-bit representation
        function addressTo32Bits(address addr) public pure returns (uint32) {
            return uint32(uint160(addr));
        }
    }