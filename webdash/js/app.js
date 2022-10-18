var websocketclient = {
    'client': null,

    'connect': function () {
        var host = "websocket.iot.fr-par.scw.cloud";
        var port = 80;
        var clientId = "sub";
        var username = "1dda7d33-ff6e-4fa1-aa17-2b56f47b89d2";
        var password = "";
        var keepAlive = 60;
        var cleanSession = true;
        var ssl = false;

        this.client = new Paho.MQTT.Client(host, port, clientId);
        this.client.onConnectionLost = this.onConnectionLost;
        this.client.onMessageArrived = this.onMessageArrived;

        var options = {
            timeout: 3,
            keepAliveInterval: keepAlive,
            cleanSession: cleanSession,
            useSSL: ssl,
            onSuccess: this.onConnect,
            onFailure: this.onFail
        };

        options.userName = username;
        options.password = password;

        this.client.connect(options);
    },

    'onConnect': function () {
        console.log("connected");
        
        var body = $('body').addClass('connected').removeClass('notconnected').removeClass('connectionbroke');
        websocketclient.client.subscribe("scores", {qos: 1});
    },

    'onFail': function (message) {
        console.log("error: " + message.errorMessage);
        alert('Connect failed: ' + message.errorMessage);
    },

    'onConnectionLost': function (responseObject) {
        if (responseObject.errorCode !== 0) {
            console.log("onConnectionLost:" + responseObject.errorMessage);
        }
        $('body.connected').removeClass('connected').addClass('notconnected').addClass('connectionbroke');
    },

    'onMessageArrived': function (message) {
        //console.log("onMessageArrived:" + message.payloadString + " qos: " + message.qos);

        try {
            htmlOut = "<div class='row'><div class='large-8 columns'><h3>Team Name</h3></div><div class='large-4 columns'><h3>Points</h3></div></div>";
            scores = JSON.parse(message.payloadString);
            for (const [key, value] of Object.entries(scores)) {
                htmlOut += "<div class='row'><div class='large-8 columns'>&nbsp;</div><div class='large-4 columns'>&nbsp;</div></div>";
                htmlOut += "<div class='row'><div class='large-8 columns'>" + key + "</div><div class='large-4 columns'>" + value + "</div></div>";
            }
            $("#scoreCard").html(htmlOut);
        } catch (e) {
            console.log("Can't parse scorecard: " + e.message);
        }

    },
};
