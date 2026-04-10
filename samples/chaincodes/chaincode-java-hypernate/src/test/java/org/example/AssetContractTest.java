/*
 * SPDX-License-Identifier: Apache-2.0
 */
package org.example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import hu.bme.mit.ftsrg.hypernate.context.HypernateContext;
import hu.bme.mit.ftsrg.hypernate.registry.Registry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

public class AssetContractTest {

    private AssetContract contract;
    private HypernateContext ctx;
    private Registry registry;

    @BeforeEach
    void setup() {
        contract = new AssetContract();
        ctx = mock(HypernateContext.class);
        registry = mock(Registry.class);
        when(ctx.getRegistry()).thenReturn(registry);
    }

    @Nested
    class CreateAsset {

        @Test
        void createNewAsset() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(false);

            contract.createAsset(ctx, "asset1", "Alice", "blue", 500);

            verify(registry).create(new Asset("asset1", "Alice", "blue", 500));
        }

        @Test
        void createAlreadyExistingAsset() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(true);

            Exception ex = assertThrows(RuntimeException.class, () ->
                contract.createAsset(ctx, "asset1", "Alice", "blue", 500)
            );

            assertEquals("Asset asset1 already exists", ex.getMessage());
        }
    }

    @Nested
    class ReadAsset {

        @Test
        void readExistingAsset() {
            Asset expected = new Asset("asset1", "Alice", "blue", 500);
            when(registry.exists(Asset.class, "asset1")).thenReturn(true);
            when(registry.read(Asset.class, "asset1")).thenReturn(expected);

            Asset result = contract.readAsset(ctx, "asset1");

            assertEquals("Alice", result.getOwner());
            assertEquals("blue", result.getColor());
            assertEquals(500, result.getAppraisedValue());
        }

        @Test
        void readMissingAsset() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(false);

            Exception ex = assertThrows(RuntimeException.class, () ->
                contract.readAsset(ctx, "asset1")
            );

            assertEquals("Asset asset1 does not exist", ex.getMessage());
        }
    }

    @Nested
    class AssetExists {

        @Test
        void existsReturnsTrue() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(true);
            assertTrue(contract.assetExists(ctx, "asset1"));
        }

        @Test
        void existsReturnsFalse() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(false);
            assertFalse(contract.assetExists(ctx, "asset1"));
        }
    }

    @Nested
    class DeleteAsset {

        @Test
        void deleteMissingAsset() {
            when(registry.exists(Asset.class, "asset1")).thenReturn(false);

            Exception ex = assertThrows(RuntimeException.class, () ->
                contract.deleteAsset(ctx, "asset1")
            );

            assertEquals("Asset asset1 does not exist", ex.getMessage());
        }
    }
}
