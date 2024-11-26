----------------------------------------------------------------------------------
-- Company: Red~Bote
-- Engineer: Red-Bote
-- 
-- Create Date: 11/25/2024 06:18:58 PM
-- Design Name: 
-- Module Name: bagman_basys3 
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--   Based on DE10_lite Top level bagman by Dar (darfpga@aol.fr) (04/06/2018)
--   http://darfpga.blogspot.fr
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity bagman_basys3 is
    port (
        clk : in std_logic;
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;
        ps2_clk : in std_logic;
        ps2_dat : in std_logic;

        O_PMODAMP2_AIN : out std_logic;
        O_PMODAMP2_GAIN : out std_logic;
        O_PMODAMP2_SHUTD : out std_logic;

        sw : in std_logic_vector (15 downto 0));
end bagman_basys3;

architecture struct of bagman_basys3 is

    signal clock_12 : std_logic;
    signal reset : std_logic;

    signal r : std_logic_vector(2 downto 0);
    signal g : std_logic_vector(2 downto 0);
    signal b : std_logic_vector(1 downto 0);
    signal csync : std_logic;
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal blankn : std_logic;
    signal tv15Khz_mode : std_logic;

    signal audio : std_logic_vector(12 downto 0);
    signal pwm_accumulator : std_logic_vector(12 downto 0);

    signal kbd_intr : std_logic;
    signal kbd_scancode : std_logic_vector(7 downto 0);
    signal joyHBCPPFRLDU : std_logic_vector(9 downto 0);

    component clk_wiz_0
        port (
            clk_out1 : out std_logic;
            reset : in std_logic;
            locked : out std_logic;
            clk_in1 : in std_logic
        );
    end component;

begin

    reset <= '0'; -- not reset_n;
    tv15Khz_mode <= '0'; -- sw(0);

    -- Clock 12MHz for bagman core
    u_clocks : clk_wiz_0
    port map(
        clk_in1 => clk,
        reset => reset,
        clk_out1 => clock_12,
        locked => open --pll_locked
    );

    -- bagman
    bagman : entity work.bagman
        port map(
            clock_12 => clock_12,
            reset => reset,

            tv15Khz_mode => tv15Khz_mode,
            video_r => r,
            video_g => g,
            video_b => b,
            video_csync => csync,
            video_hs => hsync,
            video_vs => vsync,
            audio_out => audio,

            start2 => joyHBCPPFRLDU(6),
            start1 => joyHBCPPFRLDU(5),
            coin1 => joyHBCPPFRLDU(7),

            fire1 => joyHBCPPFRLDU(4),
            right1 => joyHBCPPFRLDU(3),
            left1 => joyHBCPPFRLDU(2),
            down1 => joyHBCPPFRLDU(1),
            up1 => joyHBCPPFRLDU(0),

            fire2 => joyHBCPPFRLDU(4),
            right2 => joyHBCPPFRLDU(3),
            left2 => joyHBCPPFRLDU(2),
            down2 => joyHBCPPFRLDU(1),
            up2 => joyHBCPPFRLDU(0)

            --dbg_cpu_addr => dbg_cpu_addr
        );
    blankn <= '1'; -- TBA

    -- adapt video to 4bits/color only
    vga_r <= r & '0' when blankn = '1' else "0000";
    vga_g <= g & '0' when blankn = '1' else "0000";
    vga_b <= b & "00" when blankn = '1' else "0000";

    ---- synchro composite/ synchro horizontale
    ----vga_hs <= csync;
    --vga_hs <= csync when tv15Khz_mode = '1' else hsync;
    ---- commutation rapide / synchro verticale
    ----vga_vs <= '1';
    --vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

    vga_hs <= hsync;
    vga_vs <= vsync;

    ----sound_string <= "00" & audio & "000" & "00" & audio & "000";

    -- get scancode from keyboard

    keyboard : entity work.io_ps2_keyboard
        port map(
            clk => clock_12, -- use same clock as main core
            kbd_clk => ps2_clk,
            kbd_dat => ps2_dat,
            interrupt => kbd_intr,
            scancode => kbd_scancode
        );

    -- translate scancode to joystick
    joystick : entity work.kbd_joystick
        port map(
            clk => clock_12, -- use same clock as main core
            kbdint => kbd_intr,
            kbdscancode => std_logic_vector(kbd_scancode),
            joyHBCPPFRLDU => joyHBCPPFRLDU,
            keys_HUA => open --keys_HUA
        );

    process (clock_12) -- use same clock as sound_board
    begin
        if rising_edge(clock_12) then
            pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned('0' & audio(12 downto 1)));
        end if;
    end process;

    -- active-low shutdown pin
    O_PMODAMP2_SHUTD <= sw(14);
    -- gain pin is driven high there is a 6 dB gain, low is a 12 dB gain 
    O_PMODAMP2_GAIN <= sw(15);

    --pwm_audio_out_l <= pwm_accumulator(12);
    --pwm_audio_out_r <= pwm_accumulator(12); 
    O_PMODAMP2_AIN <= pwm_accumulator(12);

end struct;
