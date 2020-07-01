-- Deinterleaf unit

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity deinterleave is port(
    wirein      : in std_logic_vector(7 downto 0);      -- Interleaved input
    wireout     : out std_logic_vector(3 downto 0);     -- Deinterleaved output to register
    leaved      : in std_logic;                         -- Logic '1' indicates input is interleaved and vice versa
    row         : in std_logic;                         -- Logic '1' indicates input is a row and '1' indicates input is a slice pair
    ctrl        : in std_logic_vector(1 downto 0)       -- Interleaver control logic
                                                        -- When selecting slice, ctrl == slice%4
                                                        -- When selecting row, ctrl%2 == row%2
);
end entity deinterleave;----------

architecture deinterleave_arc of deinterleave is
begin

    leave: process (wirein, ctrl, row, leaved) is
    begin

        if row = '0' then           -- Read slice

            if leaved = '0' then        -- Read from non-interleaved word (RAM Address 0-7)
                
                if ctrl = "00" then         -- Slice%4 = 0
                    wireout(1 downto 0) <= wirein(1 downto 0);
                    wireout(3 downto 2) <= (others => 'Z');
                elsif ctrl = "01" then      -- Slice%4 = 1
                    wireout(1 downto 0) <= wirein(3 downto 2);
                    wireout(3 downto 2) <= (others => 'Z');
                elsif ctrl = "10" then      -- Slice%4 = 2
                    wireout(1 downto 0) <= wirein(5 downto 4);
                    wireout(3 downto 2) <= (others => 'Z');
                elsif ctrl = "11" then      -- Slice%4 = 3
                    wireout(1 downto 0) <= wirein(7 downto 6);
                    wireout(3 downto 2) <= (others => 'Z');
                end if;

            else                        -- Read from interleaved word (RAM Address 8-199)

                if ctrl = "00" or ctrl = "10" then      -- Slice%2 = 0
                    wireout(3 downto 0) <= wirein(3 downto 0);
                else                                    -- Slice%2 = 1
                    wireout(3 downto 0) <= wirein(7 downto 4);
                end if;

            end if;

        else                        -- Read row

            if ctrl = "01" or ctrl = "11" then  -- Row%2 = 1
                wireout(0 downto 0) <= wirein(0 downto 0);
                wireout(1 downto 1) <= wirein(2 downto 2);
                wireout(2 downto 2) <= wirein(4 downto 4);
                wireout(3 downto 3) <= wirein(6 downto 6);
            else                                -- Row%2 = 0
                wireout(0 downto 0) <= wirein(1 downto 1);
                wireout(1 downto 1) <= wirein(3 downto 3);
                wireout(2 downto 2) <= wirein(5 downto 5);
                wireout(3 downto 3) <= wirein(7 downto 7);
            end if;

        end if;
        
    end process leave;

end architecture deinterleave_arc;