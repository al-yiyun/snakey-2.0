library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
	port(
		--VGA output
		clk_in_12m : in std_logic; --12mHz clock pll
		HSYNC_out : out std_logic;
		VSYNC_out : out std_logic;
		rgb_out : out std_logic_vector(5 downto 0);
		--NES
		latch : out std_logic;
		clock : out std_logic;
		data : in std_logic
	);
end top;

architecture synth of top is

component mypll is
    port(
        ref_clk_i: in std_logic;
        rst_n_i: in std_logic;
        outcore_o: out std_logic;
        outglobal_o: out std_logic
    );
end component;

component NEScontroller is 
  port(
	latch : out std_logic;
	clock : out std_logic;
	data : in std_logic;
	output : out std_logic_vector(7 downto 0);
	clk_25m : in std_logic
  );
  end component;

component vga is
	port(
		clk_in : in std_logic;
		row : out unsigned(9 downto 0);
		column : out unsigned(9 downto 0);
		valid : out std_logic;
		HSYNC : out std_logic;
		VSYNC : out std_logic
	);
end component;

component pattern_gen is
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
		
		w_enable : in std_logic;
		w_addr : in std_logic_vector(12 - 1 downto 0);
		w_data : in std_logic_vector(3 - 1 downto 0);
		
		r_data_out : out std_logic_vector(2 downto 0);
		r_addy : in std_logic_vector(12 - 1 downto 0);
		
		result : in std_logic_vector(2 downto 0)
	);
end component;

component game_logic is
	port(
		clk : in std_logic;
		
		valid : in std_logic;
		
		controller : in std_logic_vector(7 downto 0);
		
		screen_x_addy : out unsigned(5 downto 0);
		screen_y_addy : out unsigned(4 downto 0);
		
		apple_x_addy : out unsigned(9 downto 0);
		apple_y_addy : out unsigned(9 downto 0);
		
		w_enable : out std_logic;
		w_addr : out std_logic_vector(12 - 1 downto 0);
		w_data : out std_logic_vector(3 - 1 downto 0);
		
		r_data_out : in std_logic_vector(2 downto 0);
		r_addy : out std_logic_vector(12 - 1 downto 0);
		
		game_over : out std_logic;
		reset_in : in std_logic
	);
end component;

component states is
	  port(
		clk : in std_logic;
		output : in std_logic_vector(7 downto 0);
		game_over : in std_logic;
		result : out std_logic_vector(2 downto 0);
		reset_out : out std_logic
	  );
end component;


	--clock
	signal clk_25m : std_logic;
	signal clk_60hz : std_logic;
	
	--vga
	signal row : unsigned(9 downto 0);
	signal column : unsigned(9 downto 0);
	signal valid : std_logic;
	
	--NES
	signal controllerOutput : std_logic_vector(7 downto 0);
	
	-- addy screen
	signal screen_pass_x : unsigned(5 downto 0);
	signal screen_pass_y : unsigned(4 downto 0);
	
	-- apple addy
	signal apple_pass_x : unsigned (9 downto 0);
	signal apple_pass_y : unsigned (9 downto 0);
	
	--sync output
	signal rgb : std_logic_vector(5 downto 0);
	signal hsync : std_logic;
	signal vsync : std_logic;
	
	--passing RAM signals
	signal w_addr : std_logic_vector(12 - 1 downto 0);
    signal w_data : std_logic_vector(3 - 1 downto 0);
 	signal w_enable : std_logic;
	
	signal r_addy : std_logic_vector(12 - 1 downto 0);
	signal r_data_out : std_logic_vector(3 - 1 downto 0);
	
	-- fsm signals
	signal game_over_check : std_logic;
	signal result : std_logic_vector(2 downto 0);
	signal reset : std_logic;
begin 

	clk_60hz <= '1' when row = 10d"482" else '0';
	
	pll : mypll port map(ref_clk_i => clk_in_12m,
			  rst_n_i => '1',
			  outglobal_o => clk_25m); 
	
	myvga : vga port map (clk_in => clk_25m, 
						row => row,	
						column => column,
						valid => valid, 
						HSYNC => hsync, 
						VSYNC => vsync);
	
	print_pat : pattern_gen port map(clk => clk_25m, 
										row => row, 
										column => column,
										valid => valid, 
										rgb => rgb,
										screen_x_addy => screen_pass_x,
										screen_y_addy => screen_pass_y,
										apple_x_addy => apple_pass_x,
										apple_y_addy => apple_pass_y,
										r_data_out => r_data_out,
										r_addy => r_addy,
										w_addr => w_addr,
										w_data => w_data,
										w_enable => w_enable,
										result => result);	
										
	controller : NEScontroller port map(latch => latch, 
										clock => clock, 
										data => data,
										output => controllerOutput,
										clk_25m => clk_25m);

	gamelogic: game_logic port map (clk => clk_60hz,
									valid => valid,
									controller => controllerOutput,
									screen_x_addy => screen_pass_x,
									screen_y_addy => screen_pass_y,
									apple_x_addy => apple_pass_x,
									apple_y_addy => apple_pass_y,
									r_data_out => r_data_out,
									r_addy => r_addy,
									w_addr => w_addr,
									w_data => w_data,
									w_enable => w_enable,
									game_over => game_over_check,
									reset_in => reset);
	fsm_control : states port map (clk => clk_25m,
								output => controllerOutput,
								game_over => game_over_check,
								result => result,
								reset_out => reset);
	
	process(clk_25m) begin
		if rising_edge(clk_25m) then
			rgb_out <= rgb;
			HSYNC_out <= hsync;
			VSYNC_out <= vsync;
		end if;
	end process;
end;
