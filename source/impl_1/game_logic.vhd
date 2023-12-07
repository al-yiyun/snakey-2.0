library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_logic is
	port(
		clk : in std_logic;
		
		valid : in std_logic;
		
		controller : in std_logic_vector(7 downto 0);
		
		screen_x_addy : out unsigned(5 downto 0);
		screen_y_addy : out unsigned(4 downto 0);
		
		apple_x_addy : out unsigned(9 downto 0);
		apple_y_addy : out unsigned(9 downto 0);
		
		w_addr : out std_logic_vector(12 - 1 downto 0);
		w_data : out std_logic_vector(3 - 1 downto 0);
		w_enable : out std_logic;
		
		r_data_out : in std_logic_vector(2 downto 0);
		r_addy : out std_logic_vector(12 - 1 downto 0);
		
		game_over : out std_logic;
		reset_in : in std_logic
	);
end game_logic;

architecture synth of game_logic is

	--moving snake counter
	signal counter : unsigned(4 downto 0) := 5d"0";

	signal clkDiv : unsigned(1 downto 0) := "00";
	
	signal snake_x : unsigned(5 downto 0);		
	signal snake_y : unsigned(5 downto 0);

	--randomly generating apple	
	signal apple_x : unsigned(9 downto 0);
	signal apple_y : unsigned(9 downto 0);
	
	signal counterx : unsigned (9 downto 0) := 10d"0";
	signal countery : unsigned (9 downto 0) := 10d"0";

	signal div_x : std_logic_vector(9 downto 0);
	signal div_y : std_logic_vector(9 downto 0);

	signal dir : std_logic_vector(1 downto 0) := "11";
	
	signal write_ena : std_logic;
	signal delete_self : std_logic;
	
	signal rand_x : unsigned(9 downto 0) := "0000101010";
	signal rand_y : unsigned(9 downto 0) := "0000010101";
	
	signal next_pos_x : unsigned(5 downto 0);
	signal next_pos_y : unsigned(5 downto 0);
	
	signal last_tail_x : unsigned(5 downto 0) := "001111";
	signal last_tail_y : unsigned(5 downto 0) := "001101";
	signal last_tail_next_x : unsigned(5 downto 0) := "001111";
	signal last_tail_next_y : unsigned(5 downto 0) := "001110";
	signal tail_length : unsigned(2 downto 0);
	signal end_sig : std_logic;
	--signal next_tile : 
begin
	next_pos_x <= (snake_x - 1) when dir = "00" else
		(snake_x + 1) when dir = "01" else
		snake_x;
	next_pos_y <= (snake_y - 1) when dir = "10" else
		(snake_y + 1) when dir = "11" else
		snake_y;

	last_tail_next_x <= (last_tail_x - 1) when dir = "00" else
		(last_tail_x + 1) when dir = "01" else
		last_tail_x;
	last_tail_next_y <= (last_tail_y - 1) when dir = "10" else
		(snake_y + 1) when dir = "11" else
		snake_y;
	-- game_over <= '1' when snake_x >= 40 or snake_y >= 30 else '0';
	div_x <= std_logic_vector(counterx);
	div_y <= std_logic_vector(countery);
	r_addy <= std_logic_vector(next_pos_y) & std_logic_vector(next_pos_x);
	-- changex <= 
	
	
	process(clk) begin
		--if (reset_in) then
			--write_ena <= '1';
			--snake_x <= "001111";
			--snake_y <= "001111";
			--dir <= "11";
		if rising_edge(clk) then
			counter <= counter + 5b"1";
			counterx <= ((counterx + 10b"1") mod 40);
			countery <= ((countery + 10b"1") mod 30);
			
			--if (counter = 30) then
				--write_ena <= '1';
				--w_addr <= std_logic_vector(last_tail_y) & std_logic_vector(last_tail_x);
				--w_data <= "000"; -- erase
			if (counter = 29) then
				-- draw the body/tail
				write_ena <= '1';				
				w_addr <=  std_logic_vector(snake_y) & std_logic_vector(snake_x);
				--w_data <= "011";
				w_data <= "000";
				--game_over <= '0';
				if (next_pos_x > 39 or next_pos_y > 29) then
					game_over <= '1';
				else 
					game_over <= '0';
				end if;
			elsif (counter = 31) then
				-- draw the head and update the head position
				last_tail_x <= last_tail_next_x;
				last_tail_y <= last_tail_next_y;
				write_ena <= '1';	
				w_addr <= std_logic_vector(next_pos_y) & std_logic_vector(next_pos_x);
				--w_data <= "000";
				w_data <= "011"; -- snake head
				if (next_pos_x >= 40 and dir = "10") then
					game_over <= '1';
					snake_x <= 6d"39";
					snake_y <= (next_pos_y mod 30);
				elsif (next_pos_y >= 30 and dir = "00") then
					game_over <= '1';
					snake_x <= (next_pos_x mod 40);
					snake_y <= 6d"29";
				else
					snake_x <= (next_pos_x mod 40);
					snake_y <= (next_pos_y mod 30);
				end if;
			elsif (counter = 28 and r_data_out = "001") then
				-- draws apple at "random" locations
				write_ena <= '1';
				apple_x <= counterx;
				apple_y <= countery;
				w_addr <= div_y(5 downto 0) & div_x(5 downto 0);
				w_data <= "001";
			end if;
			dir <= "00" when controller(1) = '1' else --left
				   "01" when controller(0) = '1' else --right
				   "10" when controller(3) = '1' else --up
				   "11" when controller(2) = '1'; -- down	
			--if (next_pos_x > 39 or next_pos_y > 29) then
				--end_sig <= '1';
			--else 
				--end_sig <= '0';
			--end if;
			-- controller(6) = '1' else '0';
					-- else "01";
			
		end if;

	end process;
	w_enable <= '1' when (write_ena = '1') else '0';
	
	apple_x_addy <= apple_x;
	apple_y_addy <= apple_y;
	
	screen_x_addy <= 6d"13";
	screen_y_addy <= 5d"25";	
			
end;