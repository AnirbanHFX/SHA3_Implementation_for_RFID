library ieee;
use ieee.std_logic_1164.all;

entity chi_iota is port(
    data : in std_logic_vector(24 downto 0);
    roundn : in std_logic_vector(4 downto 0);
    slice : in std_logic_vector(5 downto 0);
    outp : out std_logic_vector(24 downto 0);
    xorbitout : out std_logic
);
end entity chi_iota;

architecture arc_chi_iota of chi_iota is

    component lut
    port (
        rnd : in std_logic_vector(4 downto 0);
        slc : in std_logic_vector(5 downto 0);
        result : out std_logic   
    );
    end component;

    signal rnd : std_logic_vector(4 downto 0);
    signal slc : std_logic_vector(5 downto 0);
    signal xorbit : std_logic;

    begin

        lut1 : lut port map(rnd, slc, xorbit);

        xorbitout <= xorbit;

        rnd <= roundn;
        slc <= slice;
        
        outp(0) <= (data(0) xor (not (data(5)) and data(10))) xor xorbit;
        outp(1) <= data(1) xor (not (data(6)) and data(11));
        outp(2) <= data(2) xor (not (data(7)) and data(12));
        outp(3) <= data(3) xor (not (data(8)) and data(13));
        outp(4) <= data(4) xor (not (data(9)) and data(14));
        outp(5) <= data(5) xor (not (data(10)) and data(15));
        outp(6) <= data(6) xor (not (data(11)) and data(16));
        outp(7) <= data(7) xor (not (data(12)) and data(17));
        outp(8) <= data(8) xor (not (data(13)) and data(18));
        outp(9) <= data(9) xor (not (data(14)) and data(19));
        outp(10) <= data(10) xor (not (data(15)) and data(20));
        outp(11) <= data(11) xor (not (data(16)) and data(21));
        outp(12) <= data(12) xor (not (data(17)) and data(22));
        outp(13) <= data(13) xor (not (data(18)) and data(23));
        outp(14) <= data(14) xor (not (data(19)) and data(24));
        outp(15) <= data(15) xor (not (data(20)) and data(0));
        outp(16) <= data(16) xor (not (data(21)) and data(1));
        outp(17) <= data(17) xor (not (data(22)) and data(2));
        outp(18) <= data(18) xor (not (data(23)) and data(3));
        outp(19) <= data(19) xor (not (data(24)) and data(4));
        outp(20) <= data(20) xor (not (data(0)) and data(5));
        outp(21) <= data(21) xor (not (data(1)) and data(6));
        outp(22) <= data(22) xor (not (data(2)) and data(7));
        outp(23) <= data(23) xor (not (data(3)) and data(8));
        outp(24) <= data(24) xor (not (data(4)) and data(9));

    end architecture arc_chi_iota;