interface dut_if(input clk);
	int a;
	int b;
	int out;
	clocking in_cb @(posedge clk);
		default input #2ns output #3ns;
		output a;
		output b;
		input out;
	endclocking
endinterface

module add(
	a,
	b,
	out,
	clk
);
input [31:0] a;
input [31:0] b;
input clk;
output [31:0] out;
reg [31:0] out;
always @(posedge clk) begin
	out <= a + b;
end
endmodule

module top();
reg clk;
reg clk1;
initial clk <= 0;
always #10ns clk <= ~clk;

dut_if dut_if1(clk);
add add1(.a(dut_if1.a), .b(dut_if1.b), .out(dut_if1.out), .clk(clk));
initial begin
	clk_gen();
end
initial begin
	$shm_open("waves.shm");
	$shm_probe("AC", top);
	dut_if1.a <= 0;
	dut_if1.b <= 0;
	repeat (100) begin
		@(dut_if1.in_cb);
		dut_if1.in_cb.a <= $urandom;
		dut_if1.in_cb.b <= $urandom;
	end
	#100;
	$finish;
end

int k;
always begin
	@(dut_if1.in_cb);
	k <= dut_if1.in_cb.out;
end

endmodule

task clk_gen();
	top.clk1 = 1'b0;
	forever #5 top.clk1 = ~top.clk1;
endtask

