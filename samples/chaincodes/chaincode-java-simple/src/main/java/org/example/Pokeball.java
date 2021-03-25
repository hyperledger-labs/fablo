/*
 * SPDX-License-Identifier: Apache2.0
 */

package org.example;

import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;
import org.json.JSONObject;

@DataType()
public class Pokeball {

    @Property()
    private String value;

    public Pokeball(){
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public String toJSONString() {
        return new JSONObject(this).toString();
    }

    public static Pokeball fromJSONString(String json) {
        String value = new JSONObject(json).getString("value");
        Pokeball asset = new Pokeball();
        asset.setValue(value);
        return asset;
    }
}
