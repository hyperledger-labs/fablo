package org.example;

import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ResponseUtils;

import java.util.List;

public class SimpleAsset extends ChaincodeBase {
    @Override
    public Response init(ChaincodeStub stub) {
        return ResponseUtils.newSuccessResponse();
    }

    @Override
    public Response invoke(ChaincodeStub stub) {
        String func = stub.getFunction();
        List<String> params = stub.getParameters();

        switch (func) {
            case "set":
                return set(stub, params);
            case "get":
                return get(stub, params);
            default:
                return ResponseUtils.newErrorResponse("Invalid function name: " + func);
        }
    }

    private Response set(ChaincodeStub stub, List<String> args) {
        if (args.size() != 2) {
            return ResponseUtils.newErrorResponse("Incorrect number of arguments. Expecting 2");
        }
        stub.putStringState(args.get(0), args.get(1));
        return ResponseUtils.newSuccessResponse("Asset saved");
    }

    private Response get(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return ResponseUtils.newErrorResponse("Incorrect number of arguments. Expecting 1");
        }
        String value = stub.getStringState(args.get(0));
        if (value.isEmpty()) {
            return ResponseUtils.newErrorResponse("Asset not found: " + args.get(0));
        }
        return ResponseUtils.newSuccessResponse(value);
    }

    public static void main(String[] args) {
        new SimpleAsset().start(args);
    }
} 