library ieee;
use ieee.std_logic_1164.all;

entity rho is port (
    r1 : in std_logic_vector(3 downto 0);
    r2 : in std_logic_vector(3 downto 0);
    rot1 : in std_logic_vector(1 downto 0);
    rot2 : in std_logic_vector(1 downto 0);
    dir : in std_logic;         -- '0' = right shift, '1' = left shift
    wordout : out std_logic_vector(7 downto 0);
    bypass_rho : in std_logic;
    clk : in std_logic;
    resetreg : in std_logic
);
end entity rho;

architecture arch_rho of rho is

    component interleave
    port (
        wireout     : out std_logic_vector(7 downto 0);
        wireup      : in std_logic_vector(3 downto 0);
        wiredown    : in std_logic_vector(3 downto 0)
    );
    end component;

    component barrelshifter
    port (
        inbits : in std_logic_vector(3 downto 0);
        outbits : out std_logic_vector(3 downto 0);
        dir : in std_logic;     -- Direction of shift, '0' = left, '1' = right
        shift : in std_logic_vector(1 downto 0)     -- Amount of shift
    );
    end component;

    component rho_register
    port (
        d : in std_logic_vector(3 downto 0);
        q : out std_logic_vector(3 downto 0);
        clk : in std_logic;
        res : in std_logic
    );
    end component;

    signal rhounit1, rhounit2 : std_logic_vector(3 downto 0);
    signal leavedoutput : std_logic_vector(7 downto 0);
    signal direction: std_logic;
    signal shift1, shift2: std_logic_vector(1 downto 0);
    signal barrel1_in, barrel2_in, barrel1_out, barrel2_out : std_logic_vector(3 downto 0);
    signal leaf1, leaf2 : std_logic_vector(3 downto 0);
    signal clock : std_logic;
    signal reset : std_logic;

    begin

        clock <= clk;
        reset <= resetreg;
        b1 : barrelshifter port map(barrel1_in, barrel1_out, direction, shift1);
        b2 : barrelshifter port map(barrel2_in, barrel2_out, direction, shift2);
        reg1 : rho_register port map(barrel1_out, rhounit1, clock, reset);
        reg2 : rho_register port map(barrel2_out, rhounit2, clock, reset);
        leaver : interleave port map(leavedoutput, leaf1, leaf2);
        wordout <= leavedoutput;

        rhoProc : process(r1, r2, rot1, rot2, bypass_rho, clk, dir, rhounit1, rhounit2) is
        begin
            if bypass_rho = '1' then
                leaf1 <= r1;
                leaf2 <= r2;
            else
                barrel1_in <= r1;
                barrel2_in <= r2;
                direction <= dir;
                shift1 <= rot1;
                shift2 <= rot2;
                leaf1 <= rhounit1;
                leaf2 <= rhounit2;
            end if;
        end process rhoProc;

    end architecture arch_rho;