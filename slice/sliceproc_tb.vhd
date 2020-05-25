library ieee;
use ieee.std_logic_1164.all;

entity sliceproc_tb is
end entity sliceproc_tb;

architecture arch_sliceproc_tb of sliceproc_tb is

    component sliceproc
    port (
        slicein : in std_logic_vector(24 downto 0);
        sliceout : out std_logic_vector(24 downto 0);
        slice : in std_logic_vector(5 downto 0);    -- For iota
        roundn : in std_logic_vector(4 downto 0);   -- For iota
        storeparity : in std_logic;     -- Rising edge causes parity of current slice to be stored in parity register
        bypass_ixp : in std_logic;      -- Logic 1 bypasses pi, chi, iota
        bypass_theta : in std_logic     -- Logic 1 bypasses theta
    );
    end component;

    signal inslice : std_logic_vector(24 downto 0);
    signal outslice : std_logic_vector(24 downto 0);
    signal slc : std_logic_vector(5 downto 0) := (others => '0');
    signal rnd : std_logic_vector(4 downto 0) := (others => '0');
    signal parclk : std_logic := '0';
    signal byp_ixp : std_logic := '1';
    signal byp_theta : std_logic := '1';

    begin

        sliceproc_component : sliceproc port map (inslice, outslice, slc, rnd, parclk, byp_ixp, byp_theta);

        inslice <= "0011111001100111100101101",
                   "1001001110100111111111101" after 200 ns;

        parclk <= '1' after 50 ns,
                  '0' after 100 ns;

        byp_theta <= '0' after 200 ns,
                     '1' after 400 ns;

    end architecture arch_sliceproc_tb;
