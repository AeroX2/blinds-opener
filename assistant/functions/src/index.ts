import * as functions from "firebase-functions";
import { smarthome } from "actions-on-google";
import "ts-polyfill/lib/es2019-array";

const app = smarthome({ debug: true });

const blindsConfig = {
    type: "action.devices.types.BLINDS",
    traits: [
        "action.devices.traits.OpenClose",
    ],
    id: "james_blinds_controller",
    otherDeviceIds: [{ deviceId: "james_blinds_controller" }],
    name: {
        name: "Blinds Controller",
        defaultNames: [],
        nicknames: [],
    },
    willReportState: false,
    attributes: {
        discreteOnlyOpenClose: true,
    },
};

app.onSync((body) => {
    return {
        requestId: body.requestId,
        payload: {
            agentUserId: "placeholder-user-id",
            devices: [blindsConfig],
        }
    };
});

app.onQuery((body) => {
    functions.logger.log('Cloud Fulfillment received QUERY');
    // Command-only devices do not support state queries
    return {
        requestId: body.requestId,
        payload: {
            devices: [{
                "james_blinds_controller": {
                    status: 'ERROR',
                    errorCode: 'notSupported',
                    debugString: `Blinds controller is command only`,
                },
            }],
        },
    };
});

app.onExecute((body) => {
    functions.logger.log('Cloud Fulfillment received EXECUTE');
    // EXECUTE requests should be handled by local fulfillment
    return {
        requestId: body.requestId,
        payload: {
            commands: body.inputs[0].payload.commands.map((command) => {
                functions.logger.error(`Cloud fallback for ${command.execution[0].command}.`,
                    `EXECUTE received for device ids: ${command.devices.map((device) => device.id)}.`);
                return {
                    ids: command.devices.map((device) => device.id),
                    status: 'ERROR',
                    errorCode: 'actionNotAvailable',
                    debugString: `Ensure devices are locally identified.`,
                };
            }),
        },
    };
});

exports.smarthome = functions.https.onRequest(app);

exports.authorize = functions.https.onRequest((req, res) => {
    const href = decodeURIComponent(req.query.redirect_uri as string);
    const state = req.query.state;
    res.status(200).send(`<a href="${href}?code=placeholder-auth-code&state=${state}">
        Complete Account Linking
	</a>`);
});

exports.token = functions.https.onRequest((req, res) => {
    res.status(200).send({
        token_type: "bearer",
        access_token: "placeholder-access-token",
        refresh_token: "placeholder-refresh-token",
        expires_in: 3600,
    });
});
