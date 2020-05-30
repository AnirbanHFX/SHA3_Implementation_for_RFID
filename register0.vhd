-- Upper 64 bit register

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity register0 is 
port(
    clk: in std_logic;                          -- Register clock
    reset: in std_logic;                        -- Register reset logic
    d: in std_logic_vector(63 downto 0);        -- Register parallel input
    q: inout std_logic_vector(63 downto 0);     -- Register parallel output
    mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
    slc : in std_logic_vector(1 downto 0);      -- Select slice, for parallel input of a slice from Slice unit
    shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
);
end entity register0;

architecture register0_arc of register0 is

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
                    if slc = "00" then
                        q(0 downto 0) <= d(0 downto 0);
                        q(2 downto 2) <= d(2 downto 2);
                        q(6 downto 6) <= d(6 downto 6);
                        q(10 downto 10) <= d(10 downto 10);
                        q(14 downto 14) <= d(14 downto 14);
                        q(18 downto 18) <= d(18 downto 18);
                        q(22 downto 22) <= d(22 downto 22);
                        q(26 downto 26) <= d(26 downto 26);
                        q(30 downto 30) <= d(30 downto 30);
                        q(34 downto 34) <= d(34 downto 34);
                        q(38 downto 38) <= d(38 downto 38);
                        q(42 downto 42) <= d(42 downto 42);
                        q(46 downto 46) <= d(46 downto 46);
                    elsif slc = "01" then
                        q(3 downto 3) <= d(3 downto 3);
                        q(7 downto 7) <= d(7 downto 7);
                        q(11 downto 11) <= d(11 downto 11);
                        q(15 downto 15) <= d(15 downto 15);
                        q(19 downto 19) <= d(19 downto 19);
                        q(23 downto 23) <= d(23 downto 23);
                        q(27 downto 27) <= d(27 downto 27);
                        q(31 downto 31) <= d(31 downto 31);
                        q(35 downto 35) <= d(35 downto 35);
                        q(39 downto 39) <= d(39 downto 39);
                        q(43 downto 43) <= d(43 downto 43);
                        q(47 downto 47) <= d(47 downto 47);
                    elsif slc = "10" then
                        q(1 downto 1) <= d(1 downto 1);
                        q(4 downto 4) <= d(4 downto 4);
                        q(8 downto 8) <= d(8 downto 8);
                        q(12 downto 12) <= d(12 downto 12);
                        q(16 downto 16) <= d(16 downto 16);
                        q(20 downto 20) <= d(20 downto 20);
                        q(24 downto 24) <= d(24 downto 24);
                        q(28 downto 28) <= d(28 downto 28);
                        q(32 downto 32) <= d(32 downto 32);
                        q(36 downto 36) <= d(36 downto 36);
                        q(40 downto 40) <= d(40 downto 40);
                        q(44 downto 44) <= d(44 downto 44);
                        q(48 downto 48) <= d(48 downto 48);
                    else
                        q(5 downto 5) <= d(5 downto 5);
                        q(9 downto 9) <= d(9 downto 9);
                        q(13 downto 13) <= d(13 downto 13);
                        q(17 downto 17) <= d(17 downto 17);
                        q(21 downto 21) <= d(21 downto 21);
                        q(25 downto 25) <= d(25 downto 25);
                        q(29 downto 29) <= d(29 downto 29);
                        q(33 downto 33) <= d(33 downto 33);
                        q(37 downto 37) <= d(37 downto 37);
                        q(41 downto 41) <= d(41 downto 41);
                        q(45 downto 45) <= d(45 downto 45);
                        q(49 downto 49) <= d(49 downto 49);
                    end if;
                end if;
            end if;
        end process io;

end register0_arc;


