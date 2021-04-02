#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <DNSServer.h>
#include <WiFiClient.h>
#include <WiFiManager.h>
#include <ArduinoOTA.h>
#include <ArduinoJson.h>
#include <Time.h>
#include <TimeAlarms.h>
#include <ESP8266mDNS.h>

#define MOTOR_SIGNAL_A 8
#define MOTOR_SIGNAL_B 7
#define MOTOR_FORWARD  6
#define MOTOR_BACKWARD 5

#define DISCOVERY_PORT_IN  3311
#define DISCOVERY_PORT_OUT 3312
char incoming_packet[256];
WiFiUDP Udp;

ESP8266WebServer server(80);

// curl -i -X POST -d '{"command": "up"}' http://blind_controller/control
AlarmID_t alarm_id = -1;
void post_control() {
  StaticJsonDocument<512> json_doc;
  String post_body = server.arg("plain");
  //Serial.println(post_body);

  auto error = deserializeJson(json_doc, server.arg("plain"));
  if (error) {
      //Serial.println("Error parsing JSON body");
      server.send(400);
      return;
  }

  const char* command = json_doc["command"];
  if (command == nullptr) {
      //Serial.println("Command not found in JSON body");
      server.send(400);
      return;
  }

  // Send the response, now so the Android app reacts a little quicker
  server.send(200, "application/json", "{\"response\": \"OK\"}");
  
  if (strcmp(command, "up") == 0) {
    digitalWrite(???, HIGH);
  } else if (strcmp(command, "down") == 0) {
    digitalWrite(???, HIGH);
  }
}

void process_discovery_packets() {
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    // Receive incoming UDP packets
    //Serial.printf("Received %d bytes from %s, port %d\n", packetSize, Udp.remoteIP().toString().c_str(), Udp.remotePort());
    int len = Udp.read(incoming_packet, 255);
    if (len > 0) {
      incoming_packet[len] = 0;
    }
    //Serial.printf("UDP packet contents: %s\n", incoming_packet);

    if (memcmp(incoming_packet, "\xA5\xA5\xA5\xA5", 4) != 0) {
      //Serial.println("Unknown UDP discovery packet data receivied");
      return;
    }

    // Send back a reply, to the IP address and port we got the packet from
    Udp.beginPacket(Udp.remoteIP(), DISCOVERY_PORT_OUT);
    Udp.write("james_blinds_controller");
    Udp.endPacket();
  }
}

void setup(void) {
  //Serial.begin(115200);
  
  WiFiManager wifiManager;
  wifiManager.autoConnect();
  
  WiFi.hostname("blinds_controller");
  //Serial.println("");
  //Serial.print("Connected to ");
  //Serial.println(WiFi.SSID());
  //Serial.print("IP address: ");
  //Serial.println(WiFi.localIP());

  if (!MDNS.begin("blinds_controller")) {
    Serial.println("Error setting up MDNS responder!");
  }
  Serial.println("mDNS responder started");

  pinMode(MOTOR_SIGNAL_A, INPUT);
  pinMode(MOTOR_SIGNAL_B, INPUT);
  pinMode(MOTOR_FORWARD, OUTPUT);
  pinMode(MOTOR_BACKWARD, OUTPUT);
  digitalWrite(MOTOR_FORWARD, LOW);
  digitalWrite(MOTOR_BACKWARD, LOW);
  
  Udp.begin(DISCOVERY_PORT_IN);
  //Serial.printf("UDP Discovery Started on: %d\n", DISCOVERY_PORT_IN);

  server.on("/", []() {
    server.send(200, "application/json", "{\"response\": \"James's Blinds controller\"}");
  });
  server.on("/control", HTTP_POST, post_control);

  server.begin();
  //Serial.printf("HTTP server started on: %d\n", 80);

  ArduinoOTA.setHostname("blinds_controller");
  ArduinoOTA.onStart([]() {
    Serial.println("Start");
  });
  ArduinoOTA.onEnd([]() {
    Serial.println("\nEnd");
  });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
    else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
    else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
    else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
    else if (error == OTA_END_ERROR) Serial.println("End Failed");
  });
  ArduinoOTA.begin();
}

void loop(void) {
  process_discovery_packets();
  server.handleClient();
  ArduinoOTA.handle();
}
