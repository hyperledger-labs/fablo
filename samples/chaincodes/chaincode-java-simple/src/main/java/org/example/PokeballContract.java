/*
 * SPDX-License-Identifier: Apache2.0
 */
package org.example;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.contract.annotation.Contact;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.License;
import static java.nio.charset.StandardCharsets.UTF_8;

@Contract(name = "PokeballContract",
    info = @Info(title = "Pokeball contract",
                description = "Pokeball implementation",
                version = "0.0.1",
                license =
                        @License(name = "Apache2.0",
                                url = ""),
                                contact =  @Contact(email = "PokeballContract@example.com",
                                                name = "PokeballContract",
                                                url = "http://PokeballContract.me")))
@Default
public class PokeballContract implements ContractInterface {
    public  PokeballContract() {

    }
    @Transaction()
    public boolean pokeballExists(Context ctx, String pokeballId) {
        byte[] buffer = ctx.getStub().getState(pokeballId);
        return (buffer != null && buffer.length > 0);
    }

    @Transaction()
    public void createPokeball(Context ctx, String pokeballId, String value) {
        boolean exists = pokeballExists(ctx,pokeballId);
        if (exists) {
            throw new RuntimeException("The asset "+pokeballId+" already exists");
        }
        Pokeball asset = new Pokeball();
        asset.setValue(value);
        ctx.getStub().putState(pokeballId, asset.toJSONString().getBytes(UTF_8));
    }

    @Transaction()
    public Pokeball readPokeball(Context ctx, String pokeballId) {
        boolean exists = pokeballExists(ctx,pokeballId);
        if (!exists) {
            throw new RuntimeException("The asset "+pokeballId+" does not exist");
        }

        Pokeball newAsset = Pokeball.fromJSONString(new String(ctx.getStub().getState(pokeballId),UTF_8));
        return newAsset;
    }

    @Transaction()
    public void updatePokeball(Context ctx, String pokeballId, String newValue) {
        boolean exists = pokeballExists(ctx,pokeballId);
        if (!exists) {
            throw new RuntimeException("The asset "+pokeballId+" does not exist");
        }
        Pokeball asset = new Pokeball();
        asset.setValue(newValue);

        ctx.getStub().putState(pokeballId, asset.toJSONString().getBytes(UTF_8));
    }

    @Transaction()
    public void deletePokeball(Context ctx, String pokeballId) {
        boolean exists = pokeballExists(ctx,pokeballId);
        if (!exists) {
            throw new RuntimeException("The asset "+pokeballId+" does not exist");
        }
        ctx.getStub().delState(pokeballId);
    }

}
