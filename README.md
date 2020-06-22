# SHA3_Implementation_for_RFID

## Version 1

POC implementation of https://eprint.iacr.org/2013/439.pdf - Pushing the Limits of SHA-3 Hardware Implementations to Fit on RFID.

ASIC implementation of SHA-3 Standard (https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf) that aims for lowest power consumption and lowest area overhead, to fulfil the stringent constraints of passive low-cost RFID.

## Version 2

Modification of Version 1 using only one 64 bit general purpose register instead of two. This aims to reduce area overhead further, at the cost of more clock cycles.
(Under development)