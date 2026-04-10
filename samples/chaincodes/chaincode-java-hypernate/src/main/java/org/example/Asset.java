/*
 * SPDX-License-Identifier: Apache-2.0
 */
package org.example;

import hu.bme.mit.ftsrg.hypernate.annotations.PrimaryKey;
import hu.bme.mit.ftsrg.hypernate.annotations.AttributeInfo;

/**
 * Asset represents a simple on-chain asset managed via Hypernate.
 *
 * The @PrimaryKey annotation tells Hypernate which field to use as the
 * composite key on the ledger. No manual JSON serialization or stub.putState
 * calls are needed in the contract — Hypernate's Registry handles all of that.
 */
@PrimaryKey(@AttributeInfo(name = "assetId"))
public class Asset {

    private String assetId;
    private String owner;
    private String color;
    private int appraisedValue;

    public Asset() {
    }

    public Asset(String assetId, String owner, String color, int appraisedValue) {
        this.assetId = assetId;
        this.owner = owner;
        this.color = color;
        this.appraisedValue = appraisedValue;
    }

    public String getAssetId() {
        return assetId;
    }

    public void setAssetId(String assetId) {
        this.assetId = assetId;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public int getAppraisedValue() {
        return appraisedValue;
    }

    public void setAppraisedValue(int appraisedValue) {
        this.appraisedValue = appraisedValue;
    }
}
