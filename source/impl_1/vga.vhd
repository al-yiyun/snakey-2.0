library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga is
	port(
		clk_in : in std_logic;
		row : out unsigned(9 downto 0);
		column : out unsigned(9 downto 0);
		valid : out std_logic;
		HSYNC : out std_logic;
		VSYNC : out std_logic
	);
end vga;

architecture synth of vga is

 signal row_count : unsigned(9 downto 0) := 10d"0";
 signal column_count : unsigned(9 downto 0) := 10d"0";

begin
	process(clk_in) begin
		if rising_edge(clk_in) then
			column_count <= column_count + "1";
			if column_count = 10d"660" then
				HSYNC <= '0';
			elsif column_count = 10d"756" then
				HSYNC <= '1';
			elsif column_count = 10d"799" then
				column_count <= 10d"0";
				HSYNC <= '1';
				row_count <= row_count + 10d"1";
			end if;
			
			if row_count = 10d"491" then
				VSYNC <= '0';
			elsif row_count = 10d"493" then
				VSYNC <= '1';
			elsif row_count = 10d"524" then
				row_count <= 10d"0";
			end if;
		end if;
	end process;
	valid <= '1' when (column_count < 10d"640" and row_count < 10d"480") else '0';
	row <= (row_count);
	column <= (column_count);

end;
