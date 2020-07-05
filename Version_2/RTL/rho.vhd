-- Rho Unit

library ieee;
use ieee.std_logic_1164.all;

entity rho is port (
    r : in std_logic_vector(3 downto 0);            -- Output of 64x4 Multiplexer connected to register
    rot : in std_logic_vector(1 downto 0);           -- Shift amount for Barrel Shifter
    dir : in std_logic;                             -- Barrel shifter logic : '0' = right shift, '1' = left shift
    wordout : out std_logic_vector(7 downto 0);     -- Output word from interleaver
    bypass_rho : in std_logic;                      -- Logic '1' to bypass rho operation
    clk : in std_logic;                             -- Clock to Rho registers
    resetreg : in std_logic;                        -- Reset logic for Rho registers
    leaved : in std_logic;                          -- Logic '1' indicates output is to be interleaved and vice versa
    --row : in std_logic;                             -- Logic '1' indicates output is a row and '1' indicates output is a slice pair
    leavectrl : in std_logic_vector(1 downto 0)     -- Control logic to interleaver
);
end entity rho;

architecture arch_rho of rho is

    component interleave
    port (
        wirein      : in std_logic_vector(3 downto 0);      -- 4 bit input
        wireout     : out std_logic_vector(7 downto 0);     -- Interleaved output to RAM
        leaved      : in std_logic;                         -- Logic '1' indicates output is to be interleaved and vice versa
        row         : in std_logic;                         -- Logic '1' indicates output is a row and '1' indicates output is a slice pair
        ctrl        : in std_logic_vector(1 downto 0)       -- Interleaver control logic
                                                            -- When writing slice, ctrl == slice%4
                                                            -- When writing row, ctrl%2 == row%2
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

    signal rhounit : std_logic_vector(3 downto 0);                  -- Output of rho register
    signal leavedoutput : std_logic_vector(7 downto 0);             -- Output of interleaver
    signal direction: std_logic;                                    -- Barrel shifter shift direction
    signal shift1 : std_logic_vector(1 downto 0);                   -- Barrel shifter shift amount (obtained from lower 2 bits of overall rotation amounts of respective rows)
    signal barrel_in, barrel_out : std_logic_vector(3 downto 0);    -- Barrel shifter input and output
    signal leaf : std_logic_vector(3 downto 0);                     -- Inputs to interleaver
    signal interleaver_ctrl : std_logic_vector(1 downto 0);         -- Interleaver control logic
    signal interleaver_row, interleaver_leaved : std_logic;         -- Interleaver logic - row = '0' when writing slices and vice versa; leaved = '0' when writing non-interleaved words and vice versa
    signal clock : std_logic;                                       -- Rho register clock
    signal reset : std_logic;                                       -- Rho register reset

    begin

        clock <= clk;
        reset <= resetreg;
        interleaver_ctrl <= leavectrl;
        interleaver_leaved <= leaved;
        b : barrelshifter port map(barrel_in, barrel_out, direction, shift);
        reg : rho_register port map(barrel_out, rhounit, clock, reset);
        leaver : interleave port map(leaf, leavedoutput, interleaver_leaved, interleaver_row, interleaver_ctrl);
        wordout <= leavedoutput;

        rhoProc : process(r, rot, bypass_rho, clk, dir, rhounit) is
        begin
            if bypass_rho = '1' then        -- Bypass rho unit by routing 64x4 Mux outputs to interleaver
                leaf <= r;
                interleaver_row <= '0';
            else                            -- Route data through the rho block
                barrel_in <= r;
                direction <= dir;
                shift <= rot;
                leaf <= rhounit;
                interleaver_row <= '1';
            end if;
        end process rhoProc;

    end architecture arch_rho;