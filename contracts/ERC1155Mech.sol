//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./base/Mech.sol";
import "./base/ImmutableStorage.sol";

/**
 * @dev A Mech that is operated by the holder of a defined set of minimum ERC1155 token balances
 */
contract ERC1155Mech is Mech, ImmutableStorage {
    /// @param _token Address of the token contract
    /// @param _tokenIds The token IDs
    /// @param _minBalances The minimum balances required for each token ID
    constructor(
        address _token,
        uint256[] memory _tokenIds,
        uint256[] memory _minBalances
    ) {
        bytes memory initParams = abi.encode(_token, _tokenIds, _minBalances);
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override {
        require(readImmutable().length == 0, "Already initialized");
        (, uint256[] memory _tokenIds, uint256[] memory _minBalances) = abi
            .decode(initParams, (address, uint256[], uint256[]));
        require(_tokenIds.length > 0, "No token IDs provided");
        require(_tokenIds.length == _minBalances.length, "Length mismatch");
        writeImmutable(initParams);
    }

    function token() public view returns (IERC1155) {
        (address _token, , ) = abi.decode(
            readImmutable(),
            (address, uint256[], uint256[])
        );
        return IERC1155(_token);
    }

    function tokenIds(uint256 index) public view returns (uint256) {
        (, uint256[] memory _tokenIds, ) = abi.decode(
            readImmutable(),
            (address, uint256[], uint256[])
        );
        return _tokenIds[index];
    }

    function minBalances(uint256 index) public view returns (uint256) {
        (, , uint256[] memory _minBalances) = abi.decode(
            readImmutable(),
            (address, uint256[], uint256[])
        );
        return _minBalances[index];
    }

    function isOperator(address signer) public view override returns (bool) {
        (
            address _token,
            uint256[] memory _tokenIds,
            uint256[] memory _minBalances
        ) = abi.decode(readImmutable(), (address, uint256[], uint256[]));
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                IERC1155(_token).balanceOf(signer, _tokenIds[i]) <
                _minBalances[i]
            ) {
                return false;
            }
        }
        return true;
    }
}
