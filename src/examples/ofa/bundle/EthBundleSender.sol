// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {BundleBid} from "./BundleBid.sol";

contract EthBundleSender is BundleBid {
    string[] public builderUrls;

    constructor(string[] memory builderUrls_) {
        builderUrls = builderUrls_;
    }

    function emitAndReturn(
        Suave.Bid memory bid,
        bytes memory bundleData
    ) internal virtual override returns (bytes memory) {
        for (uint i = 0; i < builderUrls.length; i++) {
            Suave.submitBundleJsonRPC(
                builderUrls[i],
                "eth_sendBundle",
                bundleData
            );
        }

        return BundleBid.emitAndReturn(bid, bundleData);
    }
}
