// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {Bid} from "../base/Bid.sol";

contract BundleBid is Bid {
    function newBid(
        uint64 decryptionCondition,
        address[] memory bidAllowedPeekers,
        address[] memory bidAllowedStores
    ) external payable returns (bytes memory) {
        require(Suave.isConfidential());

        bytes memory bundleData = this.fetchBidConfidentialBundleData();

        uint64 egp = Suave.simulateBundle(bundleData);

        Suave.Bid memory bid = Suave.newBid(
            decryptionCondition,
            bidAllowedPeekers,
            bidAllowedStores,
            "default:v0:ethBundles"
        );

        Suave.confidentialStore(bid.id, "default:v0:ethBundles", bundleData);
        Suave.confidentialStore(
            bid.id,
            "default:v0:ethBundleSimResults",
            abi.encode(egp)
        );

        return emitAndReturn(bid, bundleData);
    }

    function emitAndReturn(
        Suave.Bid memory bid,
        bytes memory
    ) internal virtual returns (bytes memory) {
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
        return bytes.concat(this.emitBid.selector, abi.encode(bid));
    }
}
