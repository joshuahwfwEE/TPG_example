# TPG_example
this is a small project which is reference from xilinx video series XVES0004, you can simulate the xilinx tpg's behavior through AXI VIP as the master instaed of using any processor


cd /your/location

git clone /this/repository

source create_proj.tcl

you can rebuild the project

this is the simulation result, if you run successfully, you will see the test success in tcl command line.

![alt text](https://github.com/joshuahwfwEE/TPG_example/blob/main/tpg_sim.png?raw=true)

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
