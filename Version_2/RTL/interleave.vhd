-- Interleaf unit

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity interleave is port(
    wirein      : in std_logic_vector(3 downto 0);      -- 4 bit input
    wireout     : out std_logic_vector(7 downto 0);     -- Interleaved output to RAM
    leaved      : in std_logic;                         -- Logic '1' indicates output is to be interleaved and vice versa
    row         : in std_logic;                         -- Logic '1' indicates output is a row and '1' indicates output is a slice pair
    ctrl        : in std_logic_vector(1 downto 0)       -- Interleaver control logic
                                                        -- When writing slice, ctrl == slice%4
                                                        -- When writing row, ctrl%2 == row%2
);
end entity interleave;

architecture interleave_arc of interleave is
begin

    leave: process (wirein, ctrl, row, leaved) is
    begin

        if row = '0' then           -- Write slice

            if leaved = '0' then        -- Write to non-interleaved word (RAM Address 0-7)
                
                if ctrl = "00" then         -- Slice%4 = 0
                    wireout(1 downto 0) <= wirein(1 downto 0);
                    wireout(7 downto 2) <= (others => 'Z');
                elsif ctrl = "01" then      -- Slice%4 = 1
                    wireout(1 downto 0) <= (others => 'Z');
                    wireout(3 downto 2) <= wirein(1 downto 0);
                    wireout(7 downto 4) <= (others => 'Z');
                elsif ctrl = "10" then      -- Slice%4 = 2
                    wireout(3 downto 0) <= (others => 'Z');
                    wireout(5 downto 4) <= wirein(1 downto 0);
                    wireout(7 downto 6) <= (others => 'Z');
                elsif ctrl = "11" then      -- Slice%4 = 3
                    wireout(5 downto 0) <= (others => 'Z');
                    wireout(7 downto 6) <= wirein(1 downto 0);
                end if;

            else                        -- Write to interleaved word (RAM Address 8-199)

                if ctrl = "00" or ctrl = "10" then      -- Slice%2 = 0
                    wireout(3 downto 0) <= wirein(3 downto 0);
                    wireout(7 downto 4) <= (others => 'Z');
                else                                    -- Slice%2 = 1
                    wireout(3 downto 0) <= (others => 'Z');
                    wireout(7 downto 4) <= wirein(3 downto 0);
                end if;

            end if;

        else                        -- Write row

            if ctrl = "01" or ctrl = "11" then     -- Row%2 == 1
                wireout(0 downto 0) <= wirein(0 downto 0);
                wireout(1 downto 1) <= (others => 'Z');
                wireout(2 downto 2) <= wirein(1 downto 1);
                wireout(3 downto 3) <= (others => 'Z');
                wireout(4 downto 4) <= wirein(2 downto 2);
                wireout(5 downto 5) <= (others => 'Z');
                wireout(6 downto 6) <= wirein(3 downto 3);
                wireout(7 downto 7) <= (others => 'Z');
            else
                wireout(0 downto 0) <= (others => 'Z');
                wireout(1 downto 1) <= wirein(0 downto 0);
                wireout(2 downto 2) <= (others => 'Z');
                wireout(3 downto 3) <= wirein(1 downto 1);
                wireout(4 downto 4) <= (others => 'Z');
                wireout(5 downto 5) <= wirein(2 downto 2);
                wireout(6 downto 6) <= (others => 'Z');
                wireout(7 downto 7) <= wirein(3 downto 3);
            end if;

        end if;
        
    end process leave;

end architecture interleave_arc;