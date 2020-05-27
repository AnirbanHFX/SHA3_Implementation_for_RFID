library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity laneproc_tb is 
end entity laneproc_tb;

architecture arch_laneproc_tb of laneproc_tb is

    component laneproc
    port (
        bypass_lane : in std_logic;                     -- When used to save slices
        clk : in std_logic;
        cntr : in std_logic_vector(3 downto 0);         -- Counter for 16 subsections of each lane
        lanepair : in std_logic_vector(4 downto 0);
        regup : in std_logic_vector(63 downto 0);
        regdwn : in std_logic_vector(63 downto 0);
        ramaddr : out std_logic_vector(8 downto 0);     -- Returns sram address where rho unit contents need to be stored
        ramword : out std_logic_vector(7 downto 0);
        ramtrig : out std_logic
    );
    end component;

    signal reg0 : std_logic_vector(63 downto 0);
    signal reg1 : std_logic_vector(63 downto 0);
    signal clock : std_logic := '1';
    signal byp : std_logic := '1';
    signal count : std_logic_vector(3 downto 0) := (others => '0');
    signal lane : std_logic_vector(4 downto 0);
    signal ramaddress : std_logic_vector(8 downto 0) := (others => 'Z');
    signal word : std_logic_vector(7 downto 0);
    signal trigger : std_logic := '0';

    signal testram : std_logic_vector(127 downto 0) := (others => '0');
    signal up, dwn : integer;
    signal divider : std_logic_vector(1 downto 0) := "00";

    begin

        laneprocessor : laneproc port map (byp, clock, count, lane, reg0, reg1, ramaddress, word, trigger);
        reg0 <= "1010101110111100001100100110111000110011111111011000111011000101";
        reg1 <= "1011000000011010111100100010011001111101000001010110101100100000";
        lane <= "00001";
        byp <= '0' after 10 ns;

        clock <= not clock after 50 ns;

        counter : process (clock, divider) is
        begin
            if rising_edge(clock) then
                divider <= std_logic_vector(to_unsigned((to_integer(unsigned(divider)) + 1) rem 3, divider'length));
                dwn <= to_integer(unsigned(count))*8;
                up <= (to_integer(unsigned(count))+1)*8-1;
            end if;
            if falling_edge(divider(1)) then
                count <= std_logic_vector(to_unsigned((to_integer(unsigned(count)) + 1) rem 16, count'length));
            end if;
        end process counter;

        testramproc : process (trigger) is
        begin
            if rising_edge(trigger) then
                testram(up downto dwn) <= word;
            end if;
        end process testramproc;

    end architecture arch_laneproc_tb;