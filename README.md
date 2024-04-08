# TPG_example
this is a small project which is reference from xilinx video series XVES0004, you can simulate the xilinx tpg's behavior through AXI VIP as the master instaed of using any processor


cd /your/location

git clone /this/repository

source create_proj.tcl

you can rebuild the project  
the main purpose is to learn how the tpg work and learn how to use the axi vip to quick develope the axi_lite master to control the ip in simulation.  
this is the simulation result, if you run successfully, you will see the test success in tcl command line.

![alt text](https://github.com/joshuahwfwEE/TPG_example/blob/main/tpg_sim.png?raw=true)  

configure different pattern by setting offset 0x20:  
Background Pattern ID (0x0020) Register  
• 0x00 - Pass the video input straight through the video output  

• 0x1 - Horizontal Ramp which increases each component (RGB or Y) horizontally by 1  

• 0x2 - Vertical Ramp which increases each component (RGB or Y) vertically by 1  

• 0x3 - Temporal Ramp which increases every pixel by a value set in the motion speed register for every frame.  

• 0x4 - Solid red output  

• 0x5 - Solid green output  

• 0x6 - Solid blue output  

• 0x7 - Solid black output  

• 0x8 - Solid white output  

• 0x9 - Color bars  

• 0xA - Zone Plate output produces a ROM based sinusoidal pattern. This option has dependencies on the motion speed, zplate horizontal starting point, zplate horizontal delta, zplate vertical starting point, and zplate vertical delta registers.  

• 0xB - Tartan Color Bars  

• 0xC - Draws a cross hatch pattern  

• 0xD - Color sweep pattern  

• 0xE - A combined vertical and horizontal ramp  

• 0xF - Black and white checker board  

• 0x10 - Pseudorandom pattern  

• 0x11 - DisplayPort color ramp  

• 0x12 - DisplayPort black and white vertical lines  

• 0x13 - DisplayPort color square    

  
the simulation has 3 main test process:  
1. frame size test:
   //test the size of the output frame is the same as configured in the TPG  
   // Start of the first frame
    @(posedge tpg_tuser)
    
   // Start of the second frame, stop the simulation
    @(posedge tpg_tuser)
    wait (tpg_tuser == 1'b0);
    #20ns;
    if((final_height == height)&&(final_width == width))
        $display("Configured and output resolution match, test succeeded");
    else
        $display("Configured and output resolution do not match, test failed");
    $finish;
   
2. pixel per line test:
//This process count the number of pixel per line (width of the image)
always @(posedge aclk)
begin
    if((tpg_tvalid==1)&&(tpg_tready==1)) begin
        if(tpg_tlast==1) begin
            final_width = counter_width + 1;
            counter_width = 0;         
        end
        else
            counter_width = counter_width + 1;           
    end
end

3. line per frame test
   //This process count the number of line per frame (height of the image)
   always @(posedge aclk)
begin
    if((tpg_tvalid==1)&&(tpg_tready==1)) begin
        if(tpg_tuser==1) begin
            final_height =  counter_height;
            counter_height = 0;       
        end
        else if(tpg_tlast==1)
            counter_height = counter_height + 1;         
    end
end
