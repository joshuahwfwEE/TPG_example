//-----------------------------------------------------------------------------
//  Copyright (c) 2020, Xilinx
//  All rights reserved.
// 
// This program is free software; distributed under the terms of BSD 3-clause 
// license ("Revised BSD License", "New BSD License", or "Modified BSD License")
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//-----------------------------------------------------------------------------
// Filename:        tb_tpg.sv
// Author:			Florent Werbrouck
// Version:         v1.0
// Description:     Simulation test bench for the Video Series 4
//                  
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

import axi_vip_pkg::*;
import TPG_sim_bd_axi_vip_0_0_pkg::*;

module tb_tpg(

    );

//////////////////////////////////////////////////////////////////////////////////
// Test Bench Signals
//////////////////////////////////////////////////////////////////////////////////
// Clock and Reset
bit aclk = 0, aresetn = 1;
// 
xil_axi_resp_t 	resp;
// Signals corresponding to the TPG AXI4-Stream interface
bit tpg_tready = 1, tpg_tuser, tpg_tvalid, tpg_tlast;
bit [23:0] tpg_tdata;
// Test Bench variables
integer counter_width = 0, counter_height = 0;
integer final_width = 0, final_height = 0;
//////////////////////////////////////////////////////////////////////////////////
// Register Space (check PG103 p15 for information)
//////////////////////////////////////////////////////////////////////////////////
//
// TPG register base address - Check the Address Editor Tab in the BD
parameter integer tpg_base_address = 12'h000;
//
// Address of some TPG registers - refer to PG103 for info
    //Control
    parameter integer TPG_CONTROL_REG       = tpg_base_address;
    // active_height
    parameter integer TPG_ACTIVE_H_REG      = tpg_base_address + 8'h10;
    // active_width
    parameter integer TPG_ACTIVE_W_REG      = tpg_base_address + 8'h18;
    // background_pattern_id
    parameter integer TPG_BG_PATTERN_ID_REG = tpg_base_address + 8'h20;
//////////////////////////////////////////////////////////////////////////////////
// VIP Configuration
integer height=400, width=640;
//////////////////////////////////////////////////////////////////////////////////


// Generate the clock : 50 MHz    
always #10ns aclk = ~aclk;

// Instanciation of the Unit Under Test (UUT)
TPG_sim_bd_wrapper UUT
(
    .aclk_50MHz    (aclk),
    .aresetn_0      (aresetn),
    .tpg_tdata      (tpg_tdata),
    .tpg_tlast      (tpg_tlast),
    .tpg_tready     (tpg_tready),
    .tpg_tuser      (tpg_tuser),
    .tpg_tvalid     (tpg_tvalid)
);

//////////////////////////////////////////////////////////////////////////////////
// Main Process. Wait to the first frame to be written and stop the simulation
// The simulation succeed if the size of the output frame is the same as configured
// in the TPG
//////////////////////////////////////////////////////////////////////////////////
//
initial begin
    //Assert the reset
    aresetn = 0;
    #340ns
    // Release the reset
    aresetn = 1;
    
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
    
end
//
//////////////////////////////////////////////////////////////////////////////////
// The following part controls the AXI VIP. 
//It follows the "Usefull Coding Guidelines and Examples" section from PG267
//////////////////////////////////////////////////////////////////////////////////
//
// Declare agent
TPG_sim_bd_axi_vip_0_0_mst_t      master_agent;
//
initial begin    

    //Create an agent
    master_agent = new("master vip agent",UUT.TPG_sim_bd_i.axi_vip_0.inst.IF);
    
    //Start the agent
    master_agent.start_master();
    
    //Wait for the reset to be released
    wait (aresetn == 1'b1);
    
    #200ns
    //Set TPG output size
    master_agent.AXI4LITE_WRITE_BURST(TPG_ACTIVE_H_REG,0,height,resp);
    master_agent.AXI4LITE_WRITE_BURST(TPG_ACTIVE_W_REG,0,width,resp);
    //Set TPG output background ID
    master_agent.AXI4LITE_WRITE_BURST(TPG_BG_PATTERN_ID_REG,0,9,resp);
    
    #200ns
    // Start the TPG in free-running mode    
    master_agent.AXI4LITE_WRITE_BURST(TPG_CONTROL_REG,0,8'h81,resp); 
      
end
//
//////////////////////////////////////////////////////////////////////////////////
//This process count the number of pixel per line (width of the image)
//////////////////////////////////////////////////////////////////////////////////
//
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
//
//////////////////////////////////////////////////////////////////////////////////
//This process count the number of line per frame (height of the image)
//////////////////////////////////////////////////////////////////////////////////
//
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
//////////////////////////////////////////////////////////////////////////////////
endmodule
