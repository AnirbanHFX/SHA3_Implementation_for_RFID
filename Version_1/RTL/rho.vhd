-- Rho Unit

library ieee;
use ieee.std_logic_1164.all;

entity rho is port (
    r1 : in std_logic_vector(3 downto 0);           -- Output of 64x4 Multiplexer connected to upper register
    r2 : in std_logic_vector(3 downto 0);           -- Output of 64x4 Multiplexer connected to lower register
    rot1 : in std_logic_vector(1 downto 0);         -- Shift amount for Barrel Shifter 1
    rot2 : in std_logic_vector(1 downto 0);         -- Shift amount for Barrel Shifter 2
    dir : in std_logic;                             -- Barrel shifter logic : '0' = right shift, '1' = left shift
    wordout : out std_logic_vector(7 downto 0);     -- Output word from interleaver
    bypass_rho : in std_logic;                      -- Logic '1' to bypass rho operation
    clk : in std_logic;                             -- Clock to Rho registers
    resetreg : in std_logic;                        -- Reset logic for Rho registers
    leavectrl : in std_logic_vector(1 downto 0)     -- Control logic to interleaver
);
end entity rho;

architecture arch_rho of rho is

    component interleave
    port (
        wireout     : out std_logic_vector(7 downto 0);     -- Interleaved output
        wireup      : in std_logic_vector(3 downto 0);      -- Input from upper register
        wiredown    : in std_logic_vector(3 downto 0);      -- Input from lower register
        ctrl        : in std_logic_vector(1 downto 0)       -- Control logic
    );
    end component;

    component barrelshifter
    port (
        inbits : in std_logic_vector(3 downto 0);       -- Input bit-string
        outbits : out std_logic_vector(3 downto 0);     -- Output bit-string
        dir : in std_logic;                             -- Direction of shift, '0' = left, '1' = right
        shift : in std_logic_vector(1 downto 0)         -- Number of bits to shift
    );
    end component;

    component rho_register
    port (
        d : in std_logic_vector(3 downto 0);        -- 4 bit input from Barrel Shifter
        q : out std_logic_vector(3 downto 0);       -- 4 bit output to Interleaver
        clk : in std_logic;                         -- q(n+1) = q(n) xor d(n) at rising edge of clock
        res : in std_logic                          -- Reset logic
    );
    end component;

    signal rhounit1, rhounit2 : std_logic_vector(3 downto 0);       -- Outputs of rho registers 
    signal leavedoutput : std_logic_vector(7 downto 0);             -- Output of interleaver
    signal direction: std_logic;                                    -- Barrel shifter shift direction
    signal shift1, shift2: std_logic_vector(1 downto 0);            -- Barrel shifter shift amounts (obtained from lower 2 bits of overall rotation amounts of respective rows)
    signal barrel1_in, barrel2_in, barrel1_out, barrel2_out : std_logic_vector(3 downto 0); -- Barrel shifter inputs and outputs
    signal leaf1, leaf2 : std_logic_vector(3 downto 0);             -- Inputs 1 and 2 to interleaver
    signal interleaver_ctrl : std_logic_vector(1 downto 0);         -- Interleaver control logic
    signal clock : std_logic;                                       -- Rho register clock
    signal reset : std_logic;                                       -- Rho register reset

    begin

        clock <= clk;
        reset <= resetreg;
        interleaver_ctrl <= leavectrl;
        b1 : barrelshifter port map(barrel1_in, barrel1_out, direction, shift1);
        b2 : barrelshifter port map(barrel2_in, barrel2_out, direction, shift2);
        reg1 : rho_register port map(barrel1_out, rhounit1, clock, reset);
        reg2 : rho_register port map(barrel2_out, rhounit2, clock, reset);
        leaver : interleave port map(leavedoutput, leaf1, leaf2, interleaver_ctrl);
        wordout <= leavedoutput;

        rhoProc : process(r1, r2, rot1, rot2, bypass_rho, clk, dir, rhounit1, rhounit2) is
        begin
            if bypass_rho = '1' then        -- Bypass rho unit by routing 64x4 Mux outputs to interleaver
                leaf1 <= r1;
                leaf2 <= r2;
            else                            -- Route data through the rho block
                barrel1_in <= r1;
                barrel2_in <= r2;
                direction <= dir;
                shift1 <= rot1;
                shift2 <= rot2;
                leaf1 <= rhounit1;
                leaf2 <= rhounit2;
            end if;
        end process rhoProc;

    end architecture arch_rho;