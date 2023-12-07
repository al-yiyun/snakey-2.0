library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pattern_gen is
	 generic (
    WORD_SIZE : natural := 3; -- Bits per word (read/write block size)
    N_WORDS : natural := 4096; -- Number of words in the memory
    ADDR_WIDTH : natural := 12 -- This should be log2 of N_WORDS; see the Big Guide to Memory for a way to eliminate this manual calculation
		);
	port(
		clk : in std_logic;
		row : in unsigned(9 downto 0);
		column : in unsigned(9 downto 0);
		valid : in std_logic;
		
		rgb : out std_logic_vector(5 downto 0);
		
		screen_x_addy : in unsigned(5 downto 0);
		screen_y_addy : in unsigned(4 downto 0);
		
		apple_x_addy : in unsigned(9 downto 0);
		apple_y_addy : in unsigned(9 downto 0);
		
		-- Pass through for writing to RAM
		w_enable : in std_logic;
		w_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		w_data : in std_logic_vector(WORD_SIZE - 1 downto 0);
		
		r_data_out : out std_logic_vector(2 downto 0);
		r_addy : in std_logic_vector(12 - 1 downto 0);
		
		--FSM result
		result : in std_logic_vector(2 downto 0)
	);
end pattern_gen;

architecture synth of pattern_gen is

	component start_screen_rom is
		port(
			clk : in std_logic;
			xaddy : in unsigned(5 downto 0);
			yaddy : in unsigned(4 downto 0);
			rgb : out std_logic_vector(5 downto 0)
		);
	end component;
	
	component game_screen_rom is
		port(
			clk : in std_logic;
			xaddy : in unsigned(5 downto 0);
			yaddy : in unsigned(4 downto 0);
			rgb : out std_logic_vector(5 downto 0)
		);
	end component;

	component snake_rom is
		port(
			clk : in std_logic;
			xaddy : in unsigned(3 downto 0);
			yaddy : in unsigned(3 downto 0);
			rgb : out std_logic_vector(5 downto 0)
		);
	end component;
	
	component dumpy_rom is
		port(
			clk : in std_logic;
			xaddy : in unsigned(4 downto 0);
			yaddy : in unsigned(4 downto 0);
			rgb : out std_logic_vector(5 downto 0)
		);
	end component;
	
	component apple_rom is
		port(
			clk : in std_logic;
			xaddy : in unsigned(3 downto 0);
			yaddy : in unsigned(3 downto 0);
			rgb : out std_logic_vector(5 downto 0)
		);
	end component;
	
	component ramdp is
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
	end component;

	--start screen signals
	signal start_screen_w : unsigned(9 downto 0);
	signal start_screen_h : unsigned(9 downto 0);
	
	signal start_screen_x : unsigned(5 downto 0);
	signal start_screen_y : unsigned(4 downto 0);
	signal make_start_screen : std_logic_vector(5 downto 0);
	
	-- end screen signals
	signal end_screen_x : unsigned(5 downto 0);
	signal end_screen_y : unsigned(4 downto 0);
	signal make_end_screen : std_logic_vector(5 downto 0);
	
	-- snake ROM signals
	signal snake_size_w : unsigned(9 downto 0);
	signal snake_size_h : unsigned(9 downto 0);

	signal rom_x : unsigned(3 downto 0);
	signal rom_y : unsigned(3 downto 0);
	signal color_snake_alive : std_logic_vector(5 downto 0);
	
	signal dumpy_x : unsigned(4 downto 0);
	signal dumpy_y : unsigned(4 downto 0);
	signal draw_dumpy : std_logic_vector(5 downto 0);
	
	-- Apple ROM signals
	signal apple_size_w : unsigned(9 downto 0);
	signal apple_size_h : unsigned(9 downto 0);

	signal apple_rom_x : unsigned(3 downto 0);
	signal apple_rom_y : unsigned(3 downto 0);
	signal color_apple : std_logic_vector(5 downto 0);
	
	--RAM Signals
	signal r_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal r_data : std_logic_vector(WORD_SIZE - 1 downto 0);
	
	signal row_logic_vector : std_logic_vector(9 downto 0);
	signal col_logic_vector : std_logic_vector(9 downto 0);
	signal row_divide16 : std_logic_vector(5 downto 0);
	signal col_divide16 : std_logic_vector(5 downto 0);
	signal cur_tile : std_logic_vector(2 downto 0);
	signal row_tile_bound : unsigned(9 downto 0);
	signal col_tile_bound : unsigned(9 downto 0);
	signal row_tile_subtracted : unsigned(9 downto 0);
	signal col_tile_subtracted : unsigned(9 downto 0);
	
	--counter
	signal counter : unsigned(25 downto 0) := 26d"0";
	
	
begin

	--start ROM
	start_draw_screen : start_screen_rom port map(clk => clk,
									xaddy => start_screen_x,
									yaddy => start_screen_y,
									rgb => make_start_screen);

	-- end ROM
	end_game_rom_screen : game_screen_rom port map(clk => clk,
													xaddy => end_screen_x,
													yaddy => end_screen_y,
													rgb => make_end_screen);

	--snake ROM
	snake_draw_alive : snake_rom port map(clk => clk, 
									xaddy => rom_x(3 downto 0), 
									yaddy => rom_y(3 downto 0), 
									rgb => color_snake_alive);
									
	snake_dumpy : dumpy_rom port map(clk => clk,
									xaddy => dumpy_x(4 downto 0),
									yaddy => dumpy_y(4 downto 0),
									rgb => draw_dumpy);
									
	apple_draw : apple_rom port map (clk => clk,
									xaddy => apple_rom_x,
									yaddy => apple_rom_y,
									rgb => color_apple);
									
	 --RAM portmap
	ram_mod : ramdp port map(clk => clk,
						r_addr => r_addr,
						r_data => r_data,
						w_addr => w_addr,
						w_data => w_data,
						w_enable => w_enable);
	
	start_screen_x <= column(9 downto 4);
	start_screen_y <= row(8 downto 4);
	
	end_screen_x <= column(9 downto 4);
	end_screen_y <= row(8 downto 4);
		
	-- tile calculations
	col_tile_bound <= column(9 downto 4) & "0000";
	row_tile_bound <= row(9 downto 4) & "0000";
	
	col_tile_subtracted <= column - col_tile_bound;
	row_tile_subtracted <= row - row_tile_bound;
	
	-- snake drawings calculations
	rom_x <=  col_tile_subtracted(3 downto 0);
	rom_y <= row_tile_subtracted(3 downto 0);
	
	dumpy_x <= "0" & col_tile_subtracted(3 downto 0);
	dumpy_y <= "0" & col_tile_subtracted(3 downto 0);
	
	-- apple drawing calculations
	apple_rom_x <= col_tile_subtracted(3 downto 0);
	apple_rom_y <= row_tile_subtracted(3 downto 0);
	
	-- Calculates the current tile
	row_logic_vector <= std_logic_vector(row);
	col_logic_vector <= std_logic_vector(column);
	row_divide16 <= row_logic_vector(9 downto 4);
	col_divide16 <= col_logic_vector(9 downto 4);
	r_addr <= row_divide16 & col_divide16 when valid = '1' else r_addy;
	cur_tile <= r_data;
	r_data_out <= r_data;
	
	process(clk) begin -- TODO: add CLK to process
		if (rising_edge(clk)) then
			if valid = '0' then
				rgb <= "000000";
			else
					if result = "000" then
						rgb <= make_start_screen;
					elsif result = "001" then
						if (cur_tile = "000") then
							rgb <= "001001";
						elsif(cur_tile = "001")then
							rgb <= color_apple;
						elsif(cur_tile = "011") then
							rgb <= color_snake_alive;
						elsif(cur_tile = "100") then
							rgb <= draw_dumpy;
						end if;
					elsif result = "011" then 
						rgb <= make_end_screen;
					end if;
					--rgb <= make_start_screen;
			end if;
		end if;
		
			-- empty = 000
			-- apple = 001
			-- headdead = 010
			-- headalive = 011
			-- body = 100
			-- tail = 101
				
		
	end process;
	
	
end;

