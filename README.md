# Bagman-FPGA-Dar

Bagman (Stern), FPGA core by Dar (<http://darfpga.blogspot.fr>), ported to Digilent
Basys 3 (`xc7a35tcpg236-1`). Upstream:
<https://sourceforge.net/projects/darfpga/files/Software%20VHDL/bagman/>
(`vhdl_bagman_rev_0_1_2018_06_05.zip`, rev 0.1).

## Hardware

- Basys 3; VGA monitor (31 kHz) or 15 kHz TV (sw13, not verified).
- Keyboard on the onboard USB HID port.
- Optional: Atari-compatible joystick on Pmod JXADC (pins 1/2/3/4/7 =
  right/left/down/up/jump, active low, pull-ups in the XDC).
- Optional: [PmodAMP2](https://digilent.com/reference/pmod/pmodamp2/start) on Pmod JA,
  pins 1/2/4.

## Build

Requires gcc, unzip, Vivado 2020.2, and
[openFPGALoader](https://github.com/trabucayre/openFPGALoader) (`make load` only).

```
make help        # list all targets
make roms        # bagman.zip from $ROMDIR
make bitstream   # Vivado batch build (runs make roms first if needed)
make load        # program the Basys 3 over USB (SRAM, lost at power-off)
```

Overrides, as make arguments or environment variables:
`VIVADO=<path>/bin/vivado` (default `/tools/Xilinx/Vivado/2020.2/bin/vivado`),
`ROMDIR=<dir>` (default `~/roms`), `ROMZIP=<zip>[,<zip>]`.

ROMs are not included. Do not redistribute roms or anything generated from them.

## IO

Keys follow the MAME defaults. Player 2 shares the player 1 controls.

| Action   | Keyboard  | Basys 3                       |
|----------|-----------|-------------------------------|
| move     | arrows    | JXADC joystick                |
| jump     | Left Ctrl | JXADC pin 7                   |
| start 1P | 1         | btnL                          |
| start 2P | 2         | btnR                          |
| coin     | 5         | btnU / btnD                   |
| reset    |           | btnC                          |
| display  |           | sw13 (down 31 kHz, up 15 kHz) |
| amp gain |           | sw14 (up gain active)         |
| audio    |           | sw15 (up disabled)            |

## Issues Addressed

- Vivado rejects the sprite-row xor width mismatch: constants widened from 5 to 13 bits
  (`contrib/patches/bagman_xor_width.patch`).

## License

- Basys 3 port additions: MIT, see `LICENSE` (scope stated there).
- DarFPGA sources: educational use only; do not redistribute synthesized files with roms
  (see `vhdl_bagman_rev_0_1_2018_06_05/README.txt`).
- T80 CPU (`rtl_T80/`): BSD-style, Daniel Wallner et al.
