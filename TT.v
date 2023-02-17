module TT(
    //Input Port
    clk,
    rst_n,
	in_valid,
    source,
    destination,

    //Output Port
    out_valid,
    cost
    );

input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output reg          out_valid;
output reg  [3:0]   cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter S_IDLE = 3'd0;
parameter S_IN1  = 3'd1;
parameter S_IN2  = 3'd2;
parameter S_CHE1 = 3'd3;
parameter S_EXE1 = 3'd4;
parameter S_EXE2 = 3'd5;
parameter S_CHE2 = 3'd6;
parameter S_OUT  = 3'd7;
integer i,j;

//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [2:0] c_state,n_state;

//==============================================//
//                 reg declaration              //
//==============================================//

reg [15:0] connect[0:17];
reg [15:0] road[0:15];
reg [3:0] s;
reg [3:0] d;

//==============================================//
//             Current State Block              //
//==============================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= S_IDLE ; /* initial state */
    else 
        c_state <= n_state;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@(*) 
begin
    if (!rst_n) n_state=S_IDLE;
    else 
        begin
        case(c_state)
            S_IDLE:
                begin
                if (in_valid) n_state=S_IN1;
                else n_state=S_IDLE;
                end
            S_IN1:n_state=S_IN2;              
            S_IN2:
                begin
                if (in_valid) n_state=S_IN2;
                else n_state=S_CHE1;
                end
            S_CHE1:
                begin 
                if (connect[s][d]==1) n_state=S_OUT;
                else n_state=S_EXE1;
                end
            S_EXE1:n_state=S_EXE2;
            S_EXE2:n_state=S_CHE2;
            S_CHE2:
                begin 
                if (connect[16][s]==1) n_state=S_OUT;
                else if (connect[17]==connect[16]) n_state=S_OUT;
                else n_state=S_EXE1;
                end
            S_OUT:n_state=S_IDLE;
            default:n_state=S_IDLE;
        endcase
        end
end

//==============================================//
//                  Input Block                 //
//==============================================//

always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) s<=0;
else if (n_state==S_IN1) s<=source;
else s<=s;
end

always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) d<=0;
else if (n_state==S_IN1) d<=destination;
else d<=d;
end

always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) 
    begin
        for (i=0;i<18;i=i+1)
        begin
            for (j=0;j<16;j=j+1)
            begin
                connect[i][j]<=0;
            end
        end
    end
else if (n_state==S_IN1) 
    begin
        for (i=0;i<18;i=i+1)
        begin
            for (j=0;j<16;j=j+1)
            begin
                connect[i][j]<=0;
            end
        end
    end
else if (n_state==S_IN2)
        begin
            if (in_valid)
            begin
            connect[source][destination]<=1;
            connect[destination][source]<=1;
            end
        for (i=0;i<16;i=i+1)
        begin
            connect[i][i]<=1'b1;
        end
        end
else if (n_state==S_CHE1) connect[16]<=connect[d];
else if (n_state==S_EXE1) connect[17]<=connect[16];
else if (n_state==S_EXE2) connect[16]<=road[0]|road[1]|road[2]|road[3]|road[4]|road[5]|road[6]|road[7]|road[8]|road[9]|road[10]|road[11]|road[12]|road[13]|road[14]|road[15];
else 
        begin
            for (i=0;i<18;i=i+1)
            begin
            connect[i]<=connect[i];
            end
        end
end

//==============================================//
//              Calculation Block               //
//==============================================//
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n) 
        begin 
        for (i=0;i<16;i=i+1)
            begin
                for (j=0;j<16;j=j+1)
                begin
                    road[i][j]<=0;
                end
            end 
        end
    else if (n_state==S_EXE1) 
        begin
        for (i=0;i<16;i=i+1)
            begin
                if (connect[16][i]==1) road[i]<=connect[i];
                else road[i]<=0;
            end
        end
       
end
         
//==============================================//
//                Output Block                  //
//==============================================//

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        out_valid <= 0; /* remember to reset */
    else if (n_state==S_IDLE) out_valid <= 0;
    else if (n_state==S_OUT) out_valid <= 1;
    else out_valid <= 0;
end

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n) cost <= 0; /* remember to reset */
    else if(n_state==S_IDLE) cost<=0;
    else if(n_state==S_CHE1)
            begin
            if (connect[s][d]==1) 
                begin
                    if (s==d) cost<=0;
                    else cost<=1;
                end
            else cost<=1;
            end
    else if(n_state==S_CHE2)
            begin
            if (connect[16]==connect[17]) cost<=0;
            else cost<=cost+1;
            end
end 
endmodule 