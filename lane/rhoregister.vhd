library ieee;
use ieee.std_logic_1164.all;

entity rho_register is port (
    d : in std_logic_vector(3 downto 0);
    q : out std_logic_vector(3 downto 0);
    clk : in std_logic;
    res : in std_logic
);
end entity rho_register;

architecture arch_rho_register of rho_register is

    signal data : std_logic_vector(3 downto 0);

    begin

        rho_regProc : process (clk, res, d) is
        begin
            if res = '1' then
                data <= (others => '0');
            elsif rising_edge(clk) then
                data <= d xor data;
            end if;
        end process rho_regProc;

        q <= data;

    end architecture arch_rho_register;