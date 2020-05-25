library ieee;
use ieee.std_logic_1164.all;

entity sliceproc is port(
    slicein : in std_logic_vector(24 downto 0);
    sliceout : out std_logic_vector(24 downto 0);
    slice : in std_logic_vector(5 downto 0);    -- For iota
    roundn : in std_logic_vector(4 downto 0);   -- For iota
    storeparity : in std_logic;     -- Rising edge causes parity of current slice to be stored in parity register
    bypass_ixp : in std_logic;      -- Logic 1 bypasses pi, chi, iota
    bypass_theta : in std_logic     -- Logic 1 bypasses theta
);
end entity sliceproc;

architecture arch_sliceproc of sliceproc is

    component pi
    port (
        data : in std_logic_vector(24 downto 0);
        outp : out std_logic_vector(24 downto 0)
    );
    end component;

    component chi_iota
    port (
        data : in std_logic_vector(24 downto 0);
        roundn : in std_logic_vector(4 downto 0);
        slice : in std_logic_vector(5 downto 0);
        outp : out std_logic_vector(24 downto 0);
        xorbitout : out std_logic
    );
    end component;

    component bypassixp
    port (
        datain : in std_logic_vector(49 downto 0);
        dataout : out std_logic_vector(24 downto 0);
        bypass : in std_logic
    );
    end component;

    component parity
    port(
        slice : in std_logic_vector(24 downto 0);
        paritybits : out std_logic_vector(4 downto 0)
    );
    end component;

    component parityreg
    port(
        d : in std_logic_vector(4 downto 0);
        q : out std_logic_vector(4 downto 0);
        clk : in std_logic
    );
    end component;

    component theta
    port(
        slicein : in std_logic_vector(24 downto 0);
        sliceout : out std_logic_vector(24 downto 0);
        bypass : in std_logic;
        prevparity : in std_logic_vector(4 downto 0);
        curparity : in std_logic_vector(4 downto 0)
    );
    end component;

    signal inputslice : std_logic_vector(24 downto 0);
    signal pi_out : std_logic_vector(24 downto 0);
    signal chi_iota_out : std_logic_vector(24 downto 0);
    signal theta_in : std_logic_vector(24 downto 0);
    signal outputslice : std_logic_vector(24 downto 0);
    signal bypassixp_in : std_logic_vector(49 downto 0);
    signal parity_out : std_logic_vector(4 downto 0);
    signal parityreg_out : std_logic_vector(4 downto 0);
    signal parityreg_clk : std_logic;
    signal rnd : std_logic_vector(4 downto 0);
    signal slc : std_logic_vector(5 downto 0);
    signal xorbit : std_logic;          -- Debugging output
    signal byp_ixp : std_logic;
    signal byp_theta : std_logic;
    

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
        chi_iota_component : chi_iota port map(pi_out, rnd, slc, chi_iota_out, xorbit);
        bypassixp_component : bypassixp port map(bypassixp_in, theta_in, byp_ixp);
        parity_component : parity port map(theta_in, parity_out);
        parityreg_component : parityreg port map(parity_out, parityreg_out, parityreg_clk);
        theta_component : theta port map(theta_in, outputslice, byp_theta, parityreg_out, parity_out);

        sliceout <= outputslice;

    end architecture arch_sliceproc;