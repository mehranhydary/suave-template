// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";

contract Bid {
    event BidEvent(
        Suave.BidId bidId,
        uint64 decryptionCondition,
        address[] allowedPeekers
    );

    function fetchBidConfidentialBundleData()
        public
        view
        returns (bytes memory)
    {
        require(Suave.isConfidential());

        bytes memory confidentialInputs = Suave.confidentialInputs();
        return abi.decode(confidentialInputs, (bytes));
    }

    function emitBid(Suave.Bid calldata bid) public {
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
    }
}
