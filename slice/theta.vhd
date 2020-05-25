library ieee;
use ieee.std_logic_1164.all;

entity bypasstheta is port (
    datain : in std_logic_vector(4 downto 0);
    dataout : out std_logic_vector(4 downto 0);
    bypass : in std_logic
);
end entity bypasstheta;

architecture arch_bypasstheta of bypasstheta is

    begin

        bypassThetaProc : process (datain, bypass) is
        begin
            if bypass = '0' then
                dataout <= datain;
            else
                dataout <= (others => '0');
            end if;
        end process bypassThetaProc;

    end architecture arch_bypasstheta;

library ieee;
use ieee.std_logic_1164.all;

entity Theta is port (
    slicein : in std_logic_vector(24 downto 0);
    sliceout : out std_logic_vector(24 downto 0);
    bypass : in std_logic;
    prevparity : in std_logic_vector(4 downto 0);
    curparity : in std_logic_vector(4 downto 0)
);
end entity Theta;

architecture arch_Theta of Theta is

    component bypasstheta
    port (
        datain : in std_logic_vector(4 downto 0);
        dataout : out std_logic_vector(4 downto 0);
        bypass : in std_logic
    );
    end component;

    signal byp : std_logic;
    signal C, D : std_logic_vector(4 downto 0);

    begin 

        byp <= bypass;

        C(0) <= curparity(4) xor prevparity(1);
        C(1) <= curparity(0) xor prevparity(2);
        C(2) <= curparity(1) xor prevparity(3);
        C(3) <= curparity(2) xor prevparity(4);
        C(4) <= curparity(3) xor prevparity(0);

        bypasseroftheta : bypasstheta port map(C, D, byp);

        sliceout(0) <= slicein(0) xor D(0);
        sliceout(1) <= slicein(1) xor D(0);
        sliceout(2) <= slicein(2) xor D(0);
        sliceout(3) <= slicein(3) xor D(0);
        sliceout(4) <= slicein(4) xor D(0);
        sliceout(5) <= slicein(5) xor D(1);
        sliceout(6) <= slicein(6) xor D(1);
        sliceout(7) <= slicein(7) xor D(1);
        sliceout(8) <= slicein(8) xor D(1);
        sliceout(9) <= slicein(9) xor D(1);
        sliceout(10) <= slicein(10) xor D(2);
        sliceout(11) <= slicein(11) xor D(2);
        sliceout(12) <= slicein(12) xor D(2);
        sliceout(13) <= slicein(13) xor D(2);
        sliceout(14) <= slicein(14) xor D(2);
        sliceout(15) <= slicein(15) xor D(3);
        sliceout(16) <= slicein(16) xor D(3);
        sliceout(17) <= slicein(17) xor D(3);
        sliceout(18) <= slicein(18) xor D(3);
        sliceout(19) <= slicein(19) xor D(3);
        sliceout(20) <= slicein(20) xor D(4);
        sliceout(21) <= slicein(21) xor D(4);
        sliceout(22) <= slicein(22) xor D(4);
        sliceout(23) <= slicein(23) xor D(4);
        sliceout(24) <= slicein(24) xor D(4);

    end architecture arch_Theta;