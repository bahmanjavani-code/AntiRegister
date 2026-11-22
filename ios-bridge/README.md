# iOS bridge — development only
This Swift package implements the existing Android Stage 5 frame format. It does not yet connect to a phone or send SMS or carry calls.
The upstream Android socket is RFCOMM, unavailable to ordinary iOS apps for arbitrary services. Proposed replacement: authenticated encrypted local TCP over Android tethering; no cloud. Preserve existing control envelopes and audio framing.
Before enabling any telephony or SMS commands, require explicit pairing and authenticated encryption, bind only to the tethering interface, and reject unauthorized peers. Do not log SMS or credentials.
Cellular downlink and uplink need separate device validation; root and privileged app status do not guarantee audio routing. No firmware modifications are included.
Run the protocol unit tests with swift test in this directory on a supported Swift host.
