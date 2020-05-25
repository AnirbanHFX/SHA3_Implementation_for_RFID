library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity laneproc is port(
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
end entity laneproc;

architecture arch_laneproc of laneproc is

    component mux64_4
    port(
        datain : in std_logic_vector(63 downto 0);
        dataout : out std_logic_vector(3 downto 0);
        address : in std_logic_vector(3 downto 0)
    );
    end component;

    component rho
    port (
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
    end component;

    type rot_bits is array (0 to 23) of std_logic_vector(5 downto 0);
    signal rotc : rot_bits := ("000001","000011","000110","001010","001111","010101","011100","100100","101101","110111","000010","001110","011011","101001","111000","001000","011001","101011","111110","010010","100111","111101","010100","101100");

    signal bypass : std_logic;
    signal reg0, reg1 : std_logic_vector(63 downto 0);
    signal reg0bits, reg1bits : std_logic_vector(3 downto 0);
    signal upaddr, dwnaddr : std_logic_vector(3 downto 0) := (others => '0');
    signal rotup, rotdwn : std_logic_vector(1 downto 0) := (others => '0');
    signal rotdir : std_logic := '0';
    signal outpword : std_logic_vector(7 downto 0);
    signal rhoclk : std_logic := '0';
    signal state : std_logic_vector(2 downto 0) := "ZZZ";
    signal resetrho : std_logic := '0';

    begin

        bypass <= bypass_lane;
        reg0 <= regup;
        reg1 <= regdwn;
        ramword <= outpword;

        muxup : mux64_4 port map(reg0, reg0bits, upaddr);
        muxdwn : mux64_4 port map(reg1, reg1bits, dwnaddr);

        rhoblock : rho port map(reg0bits, reg1bits, rotup, rotdwn, rotdir, outpword, bypass, rhoclk, resetrho);

        laneProcess : process(bypass, clk, cntr, state, lanepair) is
        begin
            if bypass = '1' then
                upaddr <= cntr;
                dwnaddr <= cntr;
                rhoclk <= '0';
                ramtrig <= '0';
                rotdir <= '0';
                ramword <= (others => 'Z');
                ramaddr <= (others => 'Z');
                resetrho <= '1';
            else
                if clk'event then
                    state <= std_logic_vector(to_unsigned(((to_integer(unsigned(state))+1) rem 6), state'length));
                end if;
                if lanepair'event then
                    upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))) rem 16, upaddr'length));
                    dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))) rem 16, dwnaddr'length));
                end if;
            end if;
            if falling_edge(bypass) then
                state <= "000";
                upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))) rem 16, upaddr'length));
                dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))) rem 16, dwnaddr'length));
            end if;
            if state'event then
                if state = "000" then
                    --upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, upaddr'length));
                    --dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, dwnaddr'length));
                    rotup <= rotc(2*(to_integer(unsigned(lanepair))-1))(1 downto 0);
                    rotdwn <= rotc(2*(to_integer(unsigned(lanepair))-1)+1)(1 downto 0);
                    rhoclk <= '0';
                    ramtrig <= '0';
                    rotdir <= '0';
                    ramword <= (others => 'Z');
                    ramaddr <= (others => 'Z');
                    resetrho <= '1';
                elsif state = "001" then
                    resetrho <= '0';
                    rhoclk <= '1';
                elsif state = "010" then
                    rhoclk <= '0';
                    upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(upaddr))+1) rem 16, upaddr'length));
                    dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(dwnaddr))+1) rem 16, dwnaddr'length));
                    rotdir <= '1';
                    rotup <= std_logic_vector(to_unsigned(4 - to_integer(unsigned(rotup)), rotup'length));
                    rotdwn <= std_logic_vector(to_unsigned(4 - to_integer(unsigned(rotdwn)), rotdwn'length));
                elsif state = "011" then
                    rhoclk <= '1';
                elsif state = "100" then
                    rhoclk <= '0';
                    ramword <= outpword;
                    ramaddr <= std_logic_vector(to_unsigned(8+(to_integer(unsigned(lanepair))-1)*16 + to_integer(unsigned(cntr)), ramaddr'length));
                elsif state = "101" then
                    ramtrig <= '1';
                end if;
            end if;
        end process laneProcess;

    end architecture arch_laneproc;