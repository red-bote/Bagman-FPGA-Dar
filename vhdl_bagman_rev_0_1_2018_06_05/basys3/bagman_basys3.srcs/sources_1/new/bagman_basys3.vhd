---------------------------------------------------------------------------------
-- Basys 3 top level for Bagman by Red~Bote, derived from bagman_de10_lite.vhd by
-- Dar (darfpga@aol.fr, http://darfpga.blogspot.fr); see that file for its
-- history.
---------------------------------------------------------------------------------
--
-- release rev 01 : initial Basys 3 release
--  (23/10/2026)
--
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @onboard USB HID (PS/2 emulation)
--  Joystick input     @JXADC pins 1/2/3/4/7 = right/left/down/up/jump (active low)
--  Audio pwm output   @PmodAMP2 on JA pins 1/2/4; sw15 = audio disable, sw14 = gain
--
-- Uses 1 MMCM (clk_wiz_0) for 12.288MHz generation from 100MHz
--
-- Board buttons :
--   btnC : reset game
--   btnU, btnD : Add coin
--   btnL : Start 1 player
--   btnR : Start 2 players
--
-- Board switches :
--   sw13 : 0 = 31kHz VGA (line doubled), 1 = 15kHz TV (csync on hs)
--
-- Keyboard players inputs (MAME defaults) :
--
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   LEFT CTRL   : Jump
--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : move up
--   DOWN  arrow : move down
--
-- Other details : see bagman.vhd (2018 and 2014 release)
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity bagman_basys3 is
port(
  clk            : in std_logic;
  btnC           : in std_logic;
  btnU           : in std_logic;
  btnD           : in std_logic;
  btnL           : in std_logic;
  btnR           : in std_logic;
  sw             : in std_logic_vector(15 downto 0);

  vga_r     : out std_logic_vector(3 downto 0);
  vga_g     : out std_logic_vector(3 downto 0);
  vga_b     : out std_logic_vector(3 downto 0);
  vga_hs    : out std_logic;
  vga_vs    : out std_logic;

  JXADC            : in  std_logic_vector(4 downto 0);
  ps2_clk          : in  std_logic;
  ps2_dat          : in  std_logic;
  O_PMODAMP2_AIN   : out std_logic;
  O_PMODAMP2_GAIN  : out std_logic;
  O_PMODAMP2_SHUTD : out std_logic
);
end bagman_basys3;

architecture struct of bagman_basys3 is

  signal clock_12  : std_logic;
  signal reset     : std_logic;
  signal mmcm_locked : std_logic;

  signal r         : std_logic_vector(2 downto 0);
  signal g         : std_logic_vector(2 downto 0);
  signal b         : std_logic_vector(1 downto 0);
  signal csync     : std_logic;
  signal hsync     : std_logic;
  signal vsync     : std_logic;
  signal blankn    : std_logic;
  signal tv15Khz_mode : std_logic;

  signal audio           : std_logic_vector(12 downto 0);
  signal pwm_accumulator : std_logic_vector(12 downto 0);

  -- 2-FF synchronizers for the asynchronous inputs
  signal ps2_clk_meta, ps2_clk_s : std_logic := '1';
  signal ps2_dat_meta, ps2_dat_s : std_logic := '1';
  signal jxadc_meta, jxadc_s     : std_logic_vector(4 downto 0) := (others => '1');
  signal btn_meta, btn_s         : std_logic_vector(3 downto 0) := (others => '0'); -- U, D, L, R
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of ps2_clk_meta, ps2_clk_s, ps2_dat_meta, ps2_dat_s : signal is "TRUE";
  attribute ASYNC_REG of jxadc_meta, jxadc_s, btn_meta, btn_s : signal is "TRUE";

  signal kbd_intr      : std_logic;
  signal kbd_scancode  : std_logic_vector(7 downto 0);
  signal kbd_rel       : std_logic := '0';
  signal kbd_joy       : std_logic_vector(7 downto 0) := (others => '0');
  signal joyHBCPPFRLDU : std_logic_vector(9 downto 0);

begin

  -- btnC resets the MMCM; the core is held in reset until the MMCM locks
  reset <= btnC or not mmcm_locked;
  tv15Khz_mode <= sw(13);

  -- Clock 12.288MHz for bagman core
  clocks : entity work.clk_wiz_0
  port map(
    clk_in1  => clk,
    clk_out1 => clock_12,
    reset    => btnC,
    locked   => mmcm_locked
  );

  -- synchronize asynchronous inputs to the core clock
  process(clock_12)
  begin
    if rising_edge(clock_12) then
      ps2_clk_meta <= ps2_clk;      ps2_clk_s <= ps2_clk_meta;
      ps2_dat_meta <= ps2_dat;      ps2_dat_s <= ps2_dat_meta;
      jxadc_meta   <= JXADC;        jxadc_s   <= jxadc_meta;
      btn_meta     <= btnU & btnD & btnL & btnR;
      btn_s        <= btn_meta;
    end if;
  end process;

  -- bagman
  bagman : entity work.bagman
  port map(
    clock_12   => clock_12,
    reset      => reset,

    tv15Khz_mode => tv15Khz_mode,
    video_r      => r,
    video_g      => g,
    video_b      => b,
    video_csync  => csync,
    video_hs     => hsync,
    video_vs     => vsync,
    audio_out    => audio,

    start2      => joyHBCPPFRLDU(6),
    start1      => joyHBCPPFRLDU(5),
    coin1       => joyHBCPPFRLDU(7),

    fire1       => joyHBCPPFRLDU(4),
    right1      => joyHBCPPFRLDU(3),
    left1       => joyHBCPPFRLDU(2),
    down1       => joyHBCPPFRLDU(1),
    up1         => joyHBCPPFRLDU(0),

    fire2       => joyHBCPPFRLDU(4),
    right2      => joyHBCPPFRLDU(3),
    left2       => joyHBCPPFRLDU(2),
    down2       => joyHBCPPFRLDU(1),
    up2         => joyHBCPPFRLDU(0)
  );

  blankn <= '1'; -- TBA

  -- adapt video to 4bits/color only
  vga_r <= r&'0'  when blankn = '1' else "0000";
  vga_g <= g&'0'  when blankn = '1' else "0000";
  vga_b <= b&"00" when blankn = '1' else "0000";

  -- synchro composite/ synchro horizontale
  --vga_hs <= csync;
  vga_hs <= csync when tv15Khz_mode = '1' else hsync;
  -- commutation rapide / synchro verticale
  --vga_vs <= '1';
  vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

  -- get scancode from keyboard

  keyboard : entity work.io_ps2_keyboard
  port map (
    clk       => clock_12, -- use same clock as main core
    kbd_clk   => ps2_clk_s,
    kbd_dat   => ps2_dat_s,
    interrupt => kbd_intr,
    scancode  => kbd_scancode
  );

  -- translate scancode to joystick (MAME default keys, PS/2 set 2 codes)
  -- F0 marks a release; E0 is ignored, as in kbd_joystick (keypad 8/2/4/6
  -- also act as arrows, Right Ctrl as Left Ctrl).
  process(clock_12)
  begin
    if rising_edge(clock_12) then
      if kbd_intr = '1' then
        if kbd_scancode = x"F0" then
          kbd_rel <= '1';
        elsif kbd_scancode /= x"E0" then
          kbd_rel <= '0';
          if kbd_scancode = x"75" then kbd_joy(0) <= not kbd_rel; end if; -- up arrow
          if kbd_scancode = x"72" then kbd_joy(1) <= not kbd_rel; end if; -- down arrow
          if kbd_scancode = x"6B" then kbd_joy(2) <= not kbd_rel; end if; -- left arrow
          if kbd_scancode = x"74" then kbd_joy(3) <= not kbd_rel; end if; -- right arrow
          if kbd_scancode = x"14" then kbd_joy(4) <= not kbd_rel; end if; -- left ctrl : jump
          if kbd_scancode = x"16" then kbd_joy(5) <= not kbd_rel; end if; -- 1 : start 1
          if kbd_scancode = x"1E" then kbd_joy(6) <= not kbd_rel; end if; -- 2 : start 2
          if kbd_scancode = x"2E" then kbd_joy(7) <= not kbd_rel; end if; -- 5 : coin
        end if;
      end if;
    end if;
  end process;

  -- merge keyboard, JXADC joystick (active low) and buttons; player 2 mirrors
  -- player 1 as on the DE10-lite top
  joyHBCPPFRLDU(0) <= kbd_joy(0) or not jxadc_s(3);           -- up    (JXADC4)
  joyHBCPPFRLDU(1) <= kbd_joy(1) or not jxadc_s(2);           -- down  (JXADC3)
  joyHBCPPFRLDU(2) <= kbd_joy(2) or not jxadc_s(1);           -- left  (JXADC2)
  joyHBCPPFRLDU(3) <= kbd_joy(3) or not jxadc_s(0);           -- right (JXADC1)
  joyHBCPPFRLDU(4) <= kbd_joy(4) or not jxadc_s(4);           -- jump  (JXADC7)
  joyHBCPPFRLDU(5) <= kbd_joy(5) or btn_s(1);              -- start 1 (btnL)
  joyHBCPPFRLDU(6) <= kbd_joy(6) or btn_s(0);              -- start 2 (btnR)
  joyHBCPPFRLDU(7) <= kbd_joy(7) or btn_s(3) or btn_s(2);  -- coin (btnU, btnD)
  joyHBCPPFRLDU(9 downto 8) <= "00";

  -- pwm sound output

  process(clock_12)  -- use same clock as sound_board
  begin
    if rising_edge(clock_12) then
      pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned('0' & audio(12 downto 1)));
    end if;
  end process;

  O_PMODAMP2_AIN   <= pwm_accumulator(12);
  O_PMODAMP2_SHUTD <= not sw(15); -- sw15 up = amp shut down (audio disabled)
  O_PMODAMP2_GAIN  <= not sw(14); -- sw14 up = gain active (GAIN active low)

end struct;
