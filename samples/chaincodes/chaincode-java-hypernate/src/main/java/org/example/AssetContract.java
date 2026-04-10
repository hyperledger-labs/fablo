/*
 * SPDX-License-Identifier: Apache-2.0
 */
package org.example;

import hu.bme.mit.ftsrg.hypernate.contract.HypernateContract;
import hu.bme.mit.ftsrg.hypernate.context.HypernateContext;
import hu.bme.mit.ftsrg.hypernate.registry.Registry;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;

/**
 * AssetContract demonstrates how Hypernate simplifies Java chaincode.
 *
 * By extending HypernateContract instead of implementing ContractInterface
 * directly, we get access to Hypernate's Registry for object-oriented CRUD
 * operations on ledger entities, middleware support, and declarative key
 * management — without writing any manual JSON serialization or stub calls.
 */
@Contract(
    name = "AssetContract",
    info = @Info(
        title = "Asset Transfer - Hypernate Sample",
        description = "A basic asset transfer chaincode built with Hypernate",
        version = "0.0.1"
    )
)
@Default
public class AssetContract extends HypernateContract {

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void createAsset(HypernateContext ctx, String assetId, String owner, String color, int appraisedValue) {
        Registry registry = ctx.getRegistry();

        if (registry.exists(Asset.class, assetId)) {
            throw new RuntimeException("Asset " + assetId + " already exists");
        }

        Asset asset = new Asset(assetId, owner, color, appraisedValue);
        registry.create(asset);
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Asset readAsset(HypernateContext ctx, String assetId) {
        Registry registry = ctx.getRegistry();

        if (!registry.exists(Asset.class, assetId)) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        return registry.read(Asset.class, assetId);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void updateAsset(HypernateContext ctx, String assetId, String newOwner, String newColor, int newAppraisedValue) {
        Registry registry = ctx.getRegistry();

        if (!registry.exists(Asset.class, assetId)) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        Asset asset = registry.read(Asset.class, assetId);
        asset.setOwner(newOwner);
        asset.setColor(newColor);
        asset.setAppraisedValue(newAppraisedValue);
        registry.update(asset);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void deleteAsset(HypernateContext ctx, String assetId) {
        Registry registry = ctx.getRegistry();

        if (!registry.exists(Asset.class, assetId)) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        Asset asset = registry.read(Asset.class, assetId);
        registry.delete(asset);
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public boolean assetExists(HypernateContext ctx, String assetId) {
        return ctx.getRegistry().exists(Asset.class, assetId);
    }
}
