library ieee;
use ieee.std_logic_1164.all;

entity sliceproc is port(
    slicein : in std_logic_vector(24 downto 0);         -- Input slice from slice-mux
    sliceout : out std_logic_vector(24 downto 0);       -- Output slice to slice-demux
    slice : in std_logic_vector(5 downto 0);            -- Round index for Iota stage
    roundn : in std_logic_vector(4 downto 0);           -- For iota
    storeparity : in std_logic;                         -- Rising edge causes parity of current slice to be stored in parity register
    bypass_ixp : in std_logic;                          -- Logic 1 bypasses pi, chi, iota
    bypass_theta : in std_logic                         -- Logic 1 bypasses theta
);
end entity sliceproc;

architecture arch_sliceproc of sliceproc is

    component pi
    port (
        data : in std_logic_vector(24 downto 0);    -- Input slice from 100x25 Slice Multiplexer connected to both registers
        outp : out std_logic_vector(24 downto 0)    -- Output slice fed to Chi_Iota unit
    );
    end component;

    component chi_iota
    port (
        data : in std_logic_vector(24 downto 0);    -- Input slice from Pi unit
        roundn : in std_logic_vector(4 downto 0);   -- Round index (0-23)
        slice : in std_logic_vector(5 downto 0);    -- Slice index (0-63)
        outp : out std_logic_vector(24 downto 0)    -- Output slice fed Bypass_IXP mux
    );
    end component;

    component bypassixp
    port (
        datain : in std_logic_vector(49 downto 0);      -- (24-0) connected to output of IXP, (49-25) connected to input slice bypassing IXP
        dataout : out std_logic_vector(24 downto 0);    -- Output connected to Parity Unit (Theta block)
        bypass : in std_logic                           -- Output bypasses IXP if bypass == '1'
    );
    end component;

    component parity
    port(
        slice : in std_logic_vector(24 downto 0);       -- Input slice from bypass_IXP mux
        paritybits : out std_logic_vector(4 downto 0)   -- Output parity bits for each column
    );
    end component;

    component parityreg
    port(
        d : in std_logic_vector(4 downto 0);        -- Register input
        q : out std_logic_vector(4 downto 0);       -- Register output
        clk : in std_logic                          -- Output latches to Input at rising edge of clk
    );
    end component;

    component theta
    port(
        slicein : in std_logic_vector(24 downto 0);         -- Input slice from Bypass_IXP mux
        sliceout : out std_logic_vector(24 downto 0);       -- Output slice
        bypass : in std_logic;                              -- Bypass Theta (control to BypassTheta mux)
        prevparity : in std_logic_vector(4 downto 0);       -- Input from Parity register (Parity of previous slice)
        curparity : in std_logic_vector(4 downto 0)         -- Input from Parity unit (Parity of current slice)
    );
    end component;

    signal inputslice : std_logic_vector(24 downto 0);      -- Input slice to slice processor
    signal pi_out : std_logic_vector(24 downto 0);          -- Output of Pi unit
    signal chi_iota_out : std_logic_vector(24 downto 0);    -- Output of Chi_Iota unit
    signal theta_in : std_logic_vector(24 downto 0);        -- Input to Theta and Parity units
    signal outputslice : std_logic_vector(24 downto 0);     -- Output slice of slice processor
    signal bypassixp_in : std_logic_vector(49 downto 0);    -- Input to Bypass_IXP mux
    signal parity_out : std_logic_vector(4 downto 0);       -- Output of Parity unit
    signal parityreg_out : std_logic_vector(4 downto 0);    -- Output of Parity register
    signal parityreg_clk : std_logic;                       -- Parity register clock
    signal rnd : std_logic_vector(4 downto 0);              -- Round index
    signal slc : std_logic_vector(5 downto 0);              -- Slice index
    signal byp_ixp : std_logic;                             -- Bypass logic for Iota, Chi, Pi
    signal byp_theta : std_logic;                           -- Bypass logic for Theta
    

    begin

        parityreg_clk <= storeparity;
        rnd <= roundn;
        slc <= slice;
        byp_ixp <= bypass_ixp;
        byp_theta <= bypass_theta;
        inputslice <= slicein;
        bypassixp_in(49 downto 25) <= chi_iota_out(24 downto 0);
        bypassixp_in(24 downto 0) <= inputslice(24 downto 0);

        pi_component : pi port map(inputslice, pi_out);
        chi_iota_component : chi_iota port map(pi_out, rnd, slc, chi_iota_out);
        bypassixp_component : bypassixp port map(bypassixp_in, theta_in, byp_ixp);
        parity_component : parity port map(theta_in, parity_out);
        parityreg_component : parityreg port map(parity_out, parityreg_out, parityreg_clk);
        theta_component : theta port map(theta_in, outputslice, byp_theta, parityreg_out, parity_out);

        sliceout <= outputslice;

    end architecture arch_sliceproc;