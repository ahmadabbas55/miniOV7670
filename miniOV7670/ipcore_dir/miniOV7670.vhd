----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:16:17 02/19/2012 
-- Design Name: 
-- Module Name:    spartcam - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--library work;
--use work.image_pack.all ;
--use work.utils_pack.all ;
--use work.interface_pack.all ;
--use work.conf_pack.all ;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity miniOV7670 is
port( CLK : in std_logic;
		RESETN	:	in std_logic;
		TXD	:	out std_logic;
		RXD   :	in std_logic;
		
		
		--camera interface
		CAM_XCLK	:	out std_logic;
		CAM_SIOC, CAM_SIOD	:	inout std_logic; 
		CAM_DATA	:	in std_logic_vector(7 downto 0);
		CAM_PCLK, CAM_HREF, CAM_VSYNC	:	in std_logic;
		CAM_RESET	:	out std_logic ;
		
		--LCD interface
----		LCD_RS, LCD_CS, LCD_WR, LCD_RD:	out std_logic;
--		LCD_DATA :	out std_logic_vector(15 downto 0);
--		
--		--FIFO interface
--		FIFO_CS, FIFO_WR, FIFO_RD, FIFO_A0:	out std_logic;
--		FIFO_DATA :	out std_logic_vector(7 downto 0);
--		
		--HDMI interface
		TMDSp_clock:	out std_logic ;
		TMDSn_clock:	out std_logic ;
		TMDSp :	out std_logic_vector(2 downto 0);
		TMDSn :	out std_logic_vector(2 downto 0);
		--LED interface
		LED :	out std_logic_vector(7 downto 0)
		
);
end miniOV7670;

architecture Structural of miniOV7670 is
	
	component yuv_camera_interface is
	port(
 		clock : in std_logic; 
 		resetn : in std_logic; 
 		pixel_data : in std_logic_vector(7 downto 0 ); 
 		y_data : out std_logic_vector(7 downto 0 ); 
 		u_data : out std_logic_vector(7 downto 0 ); 
 		v_data : out std_logic_vector(7 downto 0 ); 
 		pixel_clock_out, hsync_out, vsync_out : out std_logic; 
 		pxclk, href, vsync : in std_logic
	); 
	end component ;
	component yuv_rgb is
	port( clk	:	in std_logic ;
			resetn	:	in std_logic ;
			pixel_clock, hsync, vsync,DE : in std_logic; 
			pixel_clock_out, hsync_out, vsync_out,DE_out : out std_logic; 
			pixel_y : in std_logic_vector(7 downto 0) ;
			pixel_u : in std_logic_vector(7 downto 0) ;
			pixel_v : in std_logic_vector(7 downto 0) ;
			pixel_r : out std_logic_vector(7 downto 0) ;
			pixel_g : out std_logic_vector(7 downto 0)  ;
			pixel_b : out std_logic_vector(7 downto 0)  
	);
	end component;
	component reset_generator is
	generic(HOLD_0	:	natural	:= 100);
	port(clk, resetn : in std_logic ;
		  resetn_0: out std_logic
		  );
	end component;
	component i2c_conf is
		generic(ADD_WIDTH : positive := 8 ; SLAVE_ADD : std_logic_vector(6 downto 0) := "0100001");
		port(
			clock : in std_logic;
			resetn : in std_logic; 		
			i2c_clk : in std_logic; 
			scl : inout std_logic; 
			sda : inout std_logic; 
			reg_addr : out std_logic_vector(ADD_WIDTH - 1 downto 0);
			reg_data : in std_logic_vector(15 downto 0)
		);
	end component;
	component yuv_register_rom is
	port(
	   clk, en	:	in std_logic ;
 		data : out std_logic_vector(15 downto 0 ); 
 		addr : in std_logic_vector(7 downto 0 )
	); 
	end component;

	COMPONENT dcm24
	PORT(
		CLKIN_IN : IN std_logic;          
		CLKDV_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;


	COMPONENT dcm96
	PORT(
		CLKIN_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;
	
	component uart_tx is
    port (            data_in : in std_logic_vector(7 downto 0);
                 write_buffer : in std_logic;
                 reset_buffer : in std_logic;
                 en_16_x_baud : in std_logic;
                   serial_out : out std_logic;
                  buffer_full : out std_logic;
             buffer_half_full : out std_logic;
                          clk : in std_logic);
    end component;

	COMPONENT HDMI_Encoder
	PORT(
			inclk 	 :in std_logic;	
			ired	    : in std_logic_vector(7 downto 0);	
			igreen    : in std_logic_vector(7 downto 0);
			iblue     : in std_logic_vector(7 downto 0);
			ihSync	 :in std_logic;	
			ivSync	 :in std_logic;	
			iDE       :in std_logic;	
			OTMDSp : out std_logic_vector(2 downto 0);	 
			OTMDSn: out std_logic_vector(2 downto 0);	 
			OTMDSp_clock:out std_logic; 
			OTMDSn_clock:out std_logic
		);
	END COMPONENT;

	signal clk_24,mid_clk_24,buff_clk_24, clk_96: std_logic ;
	signal resetn_delayed,buff_resetn_delayed, clk0 : std_logic ;

	signal pixel_y_from_interface, pixel_u_from_interface, pixel_v_from_interface : std_logic_vector(7 downto 0);
	signal pixel_r, pixel_g, pixel_b : std_logic_vector(7 downto 0);
	signal Buff_HREF : std_logic;

	
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;
	signal pxclk_from_conv, href_from_conv, vsync_from_conv : std_logic ;
	
	signal i2c_scl, i2c_sda : std_logic;
	signal rom_addr : std_logic_vector(7 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7670_vga);
	begin
	
	reset0: reset_generator 
	generic map(HOLD_0 => 50000)
	port map(clk => clk0, 
		resetn => RESETN ,
		resetn_0 => buff_resetn_delayed
	 );

	resetn_delayed <= buff_resetn_delayed;
	CAM_RESET <= '1' ;
	CAM_XCLK <= buff_clk_24 ;
	
	CAM_SIOC <= i2c_scl ;
	CAM_SIOD <= i2c_sda ;

	Inst_dcm96: dcm96 PORT MAP(
		CLKIN_IN => clk,
		CLKFX_OUT => clk_96, 
		CLKIN_IBUFG_OUT => clk0
	);	



	Inst_dcm24: dcm24 PORT MAP(
		CLKIN_IN => clk_96,
		CLKDV_OUT => clk_24
	);
	
	--signal n_clk_24: std_logic ;
	--n_clk_24 => !clk_24;
	ODDR2_inst : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE",
      INIT => '0',
      SRTYPE => "SYNC")
   port map (
      Q => buff_clk_24,    -- 1-bit output data
      C0 => clk_24,       -- 1-bit clock input
      C1 => (Not clk_24), -- 1-bit clock input
      CE => '1',              -- 1-bit clock enable input
      D0 => '1',
      D1 => '0',
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	


-- End of OBUF_inst instantiation
	 conf_rom : yuv_register_rom
	port map(
	   clk => clk_96, en => '1' ,
 		data => rom_data,
 		addr => rom_addr
	); 
 
 
 camera_conf_block : i2c_conf 
	generic map(ADD_WIDTH => 8 , SLAVE_ADD => "0100001")
	port map(
		clock => clk_96, 
		resetn => resetn_delayed ,		
 		i2c_clk => clk_24 ,
		scl => i2c_scl,
 		sda => i2c_sda, 
		reg_addr => rom_addr ,
		reg_data => rom_data
	);
	
	camera0: yuv_camera_interface
		port map(clock => clk_96,
		resetn => resetn_delayed,
		pixel_data => CAM_DATA, 
 		pxclk => CAM_PCLK, href => CAM_HREF, vsync => CAM_VSYNC,
 		pixel_clock_out => pxclk_from_interface, hsync_out => href_from_interface, vsync_out => vsync_from_interface,
 		y_data => pixel_y_from_interface,
		u_data => pixel_u_from_interface,
		v_data => pixel_v_from_interface
		);
		
		yuv_rgb0 : yuv_rgb 
		port map( clk	=> clk_96,
				resetn	=> resetn_delayed,
				pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,DE =>CAM_HREF,
				pixel_clock_out => pxclk_from_conv, hsync_out => href_from_conv, vsync_out => vsync_from_conv,DE_out =>Buff_HREF, 
				pixel_y => pixel_y_from_interface,
				pixel_u => pixel_u_from_interface,
				pixel_v => pixel_v_from_interface,
				pixel_r => pixel_r,
				pixel_g => pixel_g,
				pixel_b => pixel_b  
		);
		
			LED(3) <= resetn_delayed;  
			LED(1) <= '0';
			LED(2) <= '0';
			LED(0) <= pxclk_from_interface;  
			LED(4) <= '0';  
			LED(5) <= '0';
			LED(6) <= '0';
			LED(7) <= '0';  
	--	Buff_HREF<=	CAM_HREF;
		HDMI_Encoder0 : HDMI_Encoder		
		port map(
			inclk=>pxclk_from_interface,  
			ired=>pixel_r,--pixel_y_from_interface,--pixel_r,
			igreen=>pixel_g,--pixel_u_from_interface,--pixel_g,
			iblue=>pixel_b,--pixel_v_from_interface,--pixel_b,  
			ihSync=>href_from_conv,
			ivSync=>vsync_from_conv,
			iDE=>Buff_HREF,  
			OTMDSp=>TMDSp, 
			OTMDSn=>TMDSn,
			OTMDSp_clock=>TMDSp_clock, 
			OTMDSn_clock=>TMDSn_clock
		);		

end Structural;

