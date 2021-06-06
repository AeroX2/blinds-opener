
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <DNSServer.h>
#include <WiFiClient.h>
#include <WiFiManager.h>
#include <ArduinoOTA.h>
#include <Encoder.h>
#include <TaskScheduler.h>

#define MOTOR_SIGNAL_A D2
#define MOTOR_SIGNAL_B D7
#define MOTOR_FORWARD  D6
#define MOTOR_BACKWARD D5

#define COMMAND_PORT_IN    9377
#define DISCOVERY_PORT_IN  3311
#define DISCOVERY_PORT_OUT 3312
char incoming_packet[256];

Scheduler ts;

void handle_command_packets();
void handle_discovery_packets();
void handle_ota_update();

Task   commandPackets(10,  -1, &handle_command_packets,   &ts, true);
Task discoveryPackets(10, -1, &handle_discovery_packets, &ts, true);
// Task        otaUpdate(500, -1, &handle_ota_update,        &ts, true);

boolean start_motor();
void stop_motor();
void run_motor();

Task runMotor(0, -1, &run_motor, &ts, false, start_motor, stop_motor);

WiFiServer Tcp(COMMAND_PORT_IN);
WiFiUDP Udp;

Encoder encoder(MOTOR_SIGNAL_A, MOTOR_SIGNAL_B);

boolean windUp = false;
boolean ignore = false;
void handle_command_packets() {
  WiFiClient client = Tcp.available();
  if (!client) {
    return;
  }

//  Serial.println("Client connected");
  if (client.available()) {
    char direction = client.read();
    int delta = client.parseInt();
    windUp = direction == 'U' || direction == 'W';
    ignore = direction == 'W' || direction == 'S';

    runMotor.enableDelayed();
  
    Serial.println("Command received");
    Serial.println(direction);
  }

  while (client.available()) {
    client.read();
  }

  // close the connection:
  client.stop();
}

boolean start_motor() {
  if (ignore) {
    digitalWrite(windUp ? MOTOR_FORWARD : MOTOR_BACKWARD, HIGH);
    return true;
  }
  
  int position = encoder.read();
  if (windUp && position < 100) {
    digitalWrite(MOTOR_FORWARD, HIGH);
    return true;
  } else if (!windUp && position > 100) {
    digitalWrite(MOTOR_BACKWARD, HIGH);
    return true;
  }
  return false;
}

void run_motor() {
  int position = encoder.read();

  if (!ignore && (
       windUp && position > 32000 ||
      !windUp && position < 100)) {
    runMotor.disable();
  }
}

void stop_motor() {
  Serial.println("Stopping motor at position");
  Serial.println(encoder.read());
  digitalWrite(windUp ? MOTOR_FORWARD : MOTOR_BACKWARD, LOW);
}

void handle_discovery_packets() {
  int packetSize = Udp.parsePacket();
  if (!packetSize) {
    return;
  }
  
  // Receive incoming UDP packets
  Serial.printf("Received %d bytes from %s, port %d\n", packetSize, Udp.remoteIP().toString().c_str(), Udp.remotePort());
  int len = Udp.read(incoming_packet, UDP_TX_PACKET_MAX_SIZE);
  incoming_packet[len] = 0;
  Serial.printf("UDP packet contents: %s\n", incoming_packet);

  if (memcmp(incoming_packet, "\xA5\xA5\xA5\xA5", 4) != 0) {
    Serial.println("Unknown UDP discovery packet data receivied");
    return;
  }

  // Send back a reply, to the IP address and port we got the packet from
  Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
  Udp.write("james_blinds_controller");
  Udp.endPacket();
}

void handle_ota_update() {
  ArduinoOTA.handle();
}

void setup(void) {
  Serial.begin(115200);
  
  WiFiManager wifiManager;
  //wifiManager.setHostname("james_blinds_controller");
  // wifiManager.setSTAStaticIPConfig(ip, gateway, subnet);
  wifiManager.autoConnect();
  
  Serial.println("");
  Serial.print("Connected to ");
  Serial.println(WiFi.SSID());
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  pinMode(MOTOR_SIGNAL_A, INPUT);
  pinMode(MOTOR_SIGNAL_B, INPUT);
  pinMode(MOTOR_FORWARD, OUTPUT);
  pinMode(MOTOR_BACKWARD, OUTPUT);
  digitalWrite(MOTOR_FORWARD, LOW);
  digitalWrite(MOTOR_BACKWARD, LOW);

//  Serial.println("Pins configured");

  Tcp.begin();
  Tcp.setNoDelay(true);
  Udp.begin(DISCOVERY_PORT_IN);

//  Serial.println("Tcp and Udp server started");

//  ArduinoOTA.setHostname("blinds_controller");
//  ArduinoOTA.onStart([]() {
////    Serial.println("Start");
//  });
//  ArduinoOTA.onEnd([]() {
////    Serial.println("\nEnd");
//  });
//  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
////    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
//  });
//  ArduinoOTA.onError([](ota_error_t error) {
////    Serial.printf("Error[%u]: ", error);
//    if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
//    else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
//    else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
//    else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
//    else if (error == OTA_END_ERROR) Serial.println("End Failed");
//  });
//  ArduinoOTA.begin();
}

void loop(void) {
  ts.execute();
}
