/// <reference types="@google/local-home-sdk" />
import { Buffer } from "buffer";

// HomeApp implements IDENTIFY and EXECUTE handler for smarthome local device execution.
export class HomeApp {
    constructor(private readonly app: smarthome.App) {
        this.app = app;
    }

    public identifyHandler = async (identifyRequest: smarthome.IntentFlow.IdentifyRequest):
        Promise<smarthome.IntentFlow.IdentifyResponse> => {

        console.log("IDENTIFY request", identifyRequest);

        const device = identifyRequest.inputs[0].payload.device;
        if (device === undefined) {
            throw Error(`device is undefined: ${identifyRequest}`);
        }
        if (device.udpScanData === undefined) {
            throw Error(`identify request is missing discovery response: ${identifyRequest}`);
        }

        // Raw discovery data are encoded as 'hex'.
        const udpScanData = Buffer.from(device.udpScanData.data, "hex");
        console.debug("udpScanData:", udpScanData);
        // Device encoded discovery payload in CBOR.
        const discoveryId = udpScanData.toString();
        console.debug("discoveryData:", discoveryId);

        const identifyResponse: smarthome.IntentFlow.IdentifyResponse = {
            intent: smarthome.Intents.IDENTIFY,
            requestId: identifyRequest.requestId,
            payload: {
                device: {
                    id: device.id || "deviceId",
                    verificationId: discoveryId
                },
            },
        };
        console.log("IDENTIFY response", identifyResponse);
        return identifyResponse;
    }

    public executeHandler = (request: smarthome.IntentFlow.ExecuteRequest):
        Promise<smarthome.IntentFlow.ExecuteResponse> => {

        // Extract command(s) and device target(s) from request
        const command = request.inputs[0].payload.commands[0];
        const execution = command.execution[0];
        const params = execution.params as {
            openPercent: number,
        };

        const response = new smarthome.Execute.Response.Builder()
            .setRequestId(request.requestId);

        const result = command.devices.map((device: smarthome.IntentFlow.DeviceMetadata) => {
            let buf = Buffer.from([]);

            switch (execution.command) {
                case "action.devices.commands.OpenClose":
                    if (params.openPercent > 0) {
                        buf = Buffer.from("U0");
                    } else {
                        buf = Buffer.from("D0");
                    }
                    break;
                default:
                    throw Error(`Unsupported command: ${execution.command}`);
            }

            // Create TCP Command
            const deviceCommand = new smarthome.DataFlow.TcpRequestData();
            deviceCommand.operation = smarthome.Constants.TcpOperation.WRITE;
            deviceCommand.port = 9377;
            deviceCommand.data = buf.toString("hex");
            deviceCommand.requestId = request.requestId;
            deviceCommand.deviceId = device.id;

            console.debug("TcpCommand:", deviceCommand);

            // Send command to the local device
            return this.app.getDeviceManager()
                .send(deviceCommand)
                .then((result) => {
                    response.setSuccessState(result.deviceId, {});
                })
                .catch((err: smarthome.IntentFlow.HandlerError) => {
                    err.errorCode = err.errorCode || smarthome.IntentFlow.ErrorCode.INVALID_REQUEST;
                    response.setErrorState(device.id, err.errorCode);
                });
        });

        // Respond once all commands complete
        return Promise.all(result)
            .then(() => response.build());
    };
}
