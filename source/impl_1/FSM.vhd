library IEEE;
use IEEE.std_logic_1164.all;

entity states is
  port(
    clk : in std_logic;
	output : in std_logic_vector(7 downto 0);
    game_over : in std_logic;
    result : out std_logic_vector(2 downto 0);
	reset_out : out std_logic
  );
end states;

architecture synth of states is
type State is (START, GAME, FINAL);
signal s : State := START;

begin
  process(clk) begin
        if rising_edge(clk) then 
		if s = START then
                    if output(7) = '1' then
                    s <= GAME;
					result <= "001";
					reset_out <= '1';
                else
                    s <= START;
					result <= "000";
					reset_out <= '0';
                end if;
	elsif s = GAME then
		if game_over = '1' then
		    s <= FINAL;
			result <= "011";
		else 
			reset_out <= '0';
		    s <= GAME;
			result <= "001";
		end if;
	elsif s = FINAL then 
		if output(5) = '1' then
		    s <= START;
			result <= "000";
		else
		    s <= FINAL;
			result <= "011";
		end if;
            end if;
	end if;
  end process;
end;