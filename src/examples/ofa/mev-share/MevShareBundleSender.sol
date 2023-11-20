// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {MevShareBid} from "./MevShareBid.sol";

contract MevShareBundleSender is MevShareBid {
    string[] public builderUrls;

    constructor(string[] memory builderUrls_) {
        builderUrls = builderUrls_;
    }

    function emitMatchBidAndHint(
        Suave.Bid memory bid,
        bytes memory matchHint
    ) internal virtual override returns (bytes memory) {
        bytes memory bundleData = Suave.fillMevShareBundle(bid.id);
        for (uint i = 0; i < builderUrls.length; i++) {
            Suave.submitBundleJsonRPC(
                builderUrls[i],
                "mev_sendBundle",
                bundleData
            );
        }

        return MevShareBid.emitMatchBidAndHint(bid, matchHint);
    }
}
