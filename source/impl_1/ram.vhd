--taken from the es4 tufts website
--written by steven bell
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ramdp is
  generic (
		WORD_SIZE : natural := 3; -- Bits per word (read/write block size)
		N_WORDS : natural := 4096; -- Number of words in the memory
		ADDR_WIDTH : natural := 12 -- This should be log2 of N_WORDS; see the Big Guide to Memory for a way to eliminate this manual calculation
	);
  port (
    clk : in std_logic;
    r_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    r_data : out std_logic_vector(WORD_SIZE - 1 downto 0);
    w_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    w_data : in std_logic_vector(WORD_SIZE - 1 downto 0);
    w_enable : in std_logic
  );
end;

architecture synth of ramdp is

type ramtype is array(N_WORDS - 1 downto 0) of
    std_logic_vector(WORD_SIZE - 1 downto 0);
signal mem : ramtype := (968 => "001", others =>( others=> '0'));

begin
  process (clk) begin
	if rising_edge(clk) then
    -- Write into the memory if write enabled
  	if w_enable = '1' then
    		mem(to_integer(unsigned(w_addr))) <= w_data;
  	end if;
    -- Always read from the memory
    r_data <= mem(to_integer(unsigned(r_addr)));
	end if;
  end process;
end;