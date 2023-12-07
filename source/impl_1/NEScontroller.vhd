library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity NEScontroller is
  port(
	 latch : out std_logic;
	 clock : out std_logic;
	 data : in std_logic;
	 output : out std_logic_vector(7 downto 0);
	 clk_25m : in std_logic
  );
end NEScontroller;

architecture synth of NEScontroller is
--component HSOSC is
    --generic (
        --CLKHF_DIV : String := "0b00");
    --port(
        --CLKHFPU : in std_logic := 'X'; -- Set to 1 to power up
        --CLKHFEN : in std_logic := 'X'; -- Set to 1 to enable output
        --CLKHF   : out std_logic := 'X');
    --end component;

signal NESclk : std_logic;
signal counter : unsigned(20 downto 0);
signal NEScount : unsigned(8 downto 0);
signal shift : std_logic_vector(7 downto 0);
signal interimShift : std_logic_vector(7 downto 0);

begin

	-- clk <= clk_25m;
	--the_hsosc : HSOSC port map ('1', '1', clk);

	process(clk_25m)
		begin
		if rising_edge(clk_25m) then
			counter <= counter + 1;
			if counter > 21d"1201923" then
				counter <= 21d"0";
			end if;
		end if;
	end process;

	process(clock)
		begin
		if rising_edge(clock) then
			shift(0) <= data;
			shift(1) <= shift(0);
			shift(2) <= shift(1);
			shift(3) <= shift(2);
			shift(4) <= shift(3);
			shift(5) <= shift(4);
			shift(6) <= shift(5);
			shift(7) <= shift(6);
		end if;
	end process;

	process(counter(20))
		begin
		if(rising_edge(counter(20))) then
			if(interimShift = shift) then
				output <= not shift;
			else 
				interimShift <= shift;
			end if;
		end if;
	end process;

	NEScount <= counter(17 downto 9);
	NESclk <= counter(8);

	latch <= '1' when (NEScount = "111111111") else '0';
	clock <= NESclk when (NEScount < 0x"08") else '0';
end;