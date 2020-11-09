/*
 * SPDX-License-Identifier: Apache License 2.0
 */

package org.example;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.nio.charset.StandardCharsets;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;


public final class PokeballContractTest {

    @Nested
    class AssetExists {
        @Test
        public void noProperAsset() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            //when
            when(stub.getState("10001")).thenReturn(new byte[] {});
            boolean result = contract.pokeballExists(ctx,"10001");

            //then
            assertFalse(result);
        }

        @Test
        public void assetExists() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            //when
            when(stub.getState("10001")).thenReturn(new byte[] {42});
            boolean result = contract.pokeballExists(ctx,"10001");

            //then
            assertTrue(result);
        }

        @Test
        public void noKey() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            //when
            when(stub.getState("10002")).thenReturn(null);
            boolean result = contract.pokeballExists(ctx,"10002");

            //then
            assertFalse(result);
        }

    }

    @Nested
    class AssetCreates {

        @Test
        public void newAssetCreate() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            String json = "{\"value\":\"ThePokeball\"}";

            //when
            contract.createPokeball(ctx, "10001", "ThePokeball");

            //then
            verify(stub).putState("10001", json.getBytes(UTF_8));
        }

        @Test
        public void alreadyExists() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            when(stub.getState("10002")).thenReturn(new byte[] { 42 });

            //when
            Exception thrown = assertThrows(RuntimeException.class, () -> {
                contract.createPokeball(ctx, "10002", "ThePokeball");
            });

            //then
            assertEquals(thrown.getMessage(), "The asset 10002 already exists");

        }

    }

    @Test
    public void assetRead() {
        //given
        PokeballContract contract = new  PokeballContract();
        Context ctx = mock(Context.class);
        ChaincodeStub stub = mock(ChaincodeStub.class);
        when(ctx.getStub()).thenReturn(stub);

        Pokeball asset = new  Pokeball();
        asset.setValue("Valuable");

        String json = asset.toJSONString();
        when(stub.getState("10001")).thenReturn(json.getBytes(StandardCharsets.UTF_8));

        //when
        Pokeball returnedAsset = contract.readPokeball(ctx, "10001");

        //then
        assertEquals(returnedAsset.getValue(), asset.getValue());
    }

    @Nested
    class AssetUpdates {
        @Test
        public void updateExisting() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getState("10001")).thenReturn(new byte[] { 42 });

            //when
            contract.updatePokeball(ctx, "10001", "updates");

            //then
            String json = "{\"value\":\"updates\"}";
            verify(stub).putState("10001", json.getBytes(UTF_8));
        }

        @Test
        public void updateMissing() {
            //given
            PokeballContract contract = new  PokeballContract();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);

            when(stub.getState("10001")).thenReturn(null);

            //when
            Exception thrown = assertThrows(RuntimeException.class, () -> {
                contract.updatePokeball(ctx, "10001", "ThePokeball");
            });

            //then
            assertEquals(thrown.getMessage(), "The asset 10001 does not exist");
        }

    }

    @Test
    public void assetDelete() {
        //given
        PokeballContract contract = new  PokeballContract();
        Context ctx = mock(Context.class);
        ChaincodeStub stub = mock(ChaincodeStub.class);
        when(ctx.getStub()).thenReturn(stub);
        when(stub.getState("10001")).thenReturn(null);

        //when
        Exception thrown = assertThrows(RuntimeException.class, () -> {
            contract.deletePokeball(ctx, "10001");
        });

        //then
        assertEquals(thrown.getMessage(), "The asset 10001 does not exist");
    }

}
