-- Upper 64 bit register

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity register is 
port(
    clk: in std_logic;                          -- Register clock
    reset: in std_logic;                        -- Register reset logic
    d: in std_logic_vector(63 downto 0);        -- Register parallel input
    q: inout std_logic_vector(63 downto 0);     -- Register parallel output
    mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
    slc : in std_logic;                         -- Select slice, for parallel input of a slice from Slice unit
    shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
);
end entity register;

architecture register_arc of register is

    begin

        io: process (clk, reset) is
        begin
            if (reset='1') then                 -- Reset register
                q <= (others => '0');
            elsif (rising_edge(clk)) then
                if mode = '0' then              -- Serial input logic
                    if shift = '0' then
                        q(63 downto 4) <= q(59 downto 0);
                        q(3 downto 0) <= d(3 downto 0);
                    else
                        q(63 downto 2) <= q(61 downto 0);
                        q(1 downto 0) <= d(1 downto 0);
                    end if;
                else                            -- Parallel input logic of a slice from slice demultiplexer
                    if slc = '0' then
                        q(0 downto 0) <= d(0 downto 0);
                        q(3 downto 2) <= d(3 downto 2);
                        q(7 downto 6) <= d(7 downto 6);
                        q(11 downto 10) <= d(11 downto 10);
                        q(15 downto 14) <= d(15 downto 14);
                        q(19 downto 18) <= d(19 downto 18);
                        q(23 downto 22) <= d(23 downto 22);
                        q(27 downto 26) <= d(27 downto 26);
                        q(31 downto 30) <= d(31 downto 30);
                        q(35 downto 34) <= d(35 downto 34);
                        q(39 downto 38) <= d(39 downto 38);
                        q(43 downto 42) <= d(43 downto 42);
                        q(47 downto 46) <= d(47 downto 46);
                    else
                        q(1 downto 1) <= d(1 downto 1);
                        q(5 downto 4) <= d(5 downto 4);
                        q(9 downto 8) <= d(9 downto 8);
                        q(13 downto 12) <= d(13 downto 12);
                        q(17 downto 16) <= d(17 downto 16);
                        q(21 downto 20) <= d(21 downto 20);
                        q(25 downto 24) <= d(25 downto 24);
                        q(29 downto 28) <= d(29 downto 28);
                        q(33 downto 32) <= d(33 downto 32);
                        q(37 downto 36) <= d(37 downto 36);
                        q(41 downto 40) <= d(41 downto 40);
                        q(45 downto 44) <= d(45 downto 44);
                        q(49 downto 48) <= d(49 downto 48);
                    end if;
                end if;
            end if;
        end process io;

end register_arc;


