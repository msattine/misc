import uvm_pkg::*;
`include "uvm_macros.svh"

// Example showing usage of objection class and its functions 

class simple_comp2 extends uvm_component;
	string my_name = "comp2";
	`uvm_component_utils(simple_comp2)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	task run_phase(uvm_phase phase);
		int x = 1;
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		forever begin
		#100;
		`uvm_info(get_name(), $sformatf("In run phase of %s for iter=%0d", my_name, x++), UVM_LOW);
		end
	endtask
endclass

class simple_comp1 extends uvm_component;
	string my_name = "Comp1";
	simple_comp2 comp2;
	int option;
	`uvm_component_utils(simple_comp1)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		comp2 = simple_comp2::type_id::create(.name("comp2"), .parent(this));
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		uvm_config_db #(int)::get(.cntxt(null), .inst_name(""), .field_name("optc"), .value(option));
		if(option == 0) begin // raise objection at 0 time
			phase.raise_objection(this);
			#400;
			phase.drop_objection(this);
		end
		else if(option == 1) begin // raise objection at 100 ns
			#100;
			phase.raise_objection(this);
			#400;
			phase.drop_objection(this);
		end
	endtask
endclass

class simple_test extends uvm_test;
	string my_name = "Test";
	simple_comp1 comp1;
	int option;
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		comp1 = simple_comp1::type_id::create(.name("comp1"), .parent(this)); //This will create component of type simple_comp
	endfunction
	task run_phase(uvm_phase phase);
		uvm_config_db #(int)::get(.cntxt(null), .inst_name(""), .field_name("optt"), .value(option));
		if(option == 0) begin // raise objection at 0 time
			phase.raise_objection(this);
			#700;
			phase.drop_objection(this);
		end
		else if(option == 1) begin // raise objection at 200 ns (< 500 ns)
			#200;
			phase.raise_objection(this);
			#700;
			phase.drop_objection(this);
		end
		else if(option == 2) begin // raise objection at 600 ns (> 500 ns)
			#600;
			phase.raise_objection(this);
			#700;
			phase.drop_objection(this);
		end
	endtask
endclass

module top();
	int optc, optt;
	initial begin
		if(!$value$plusargs("optc=%d", optc))
			optc = 0; 
		if(!$value$plusargs("optt=%d", optt))
			optt = 0;
		`uvm_info("TB_TOP", $sformatf("Launching the test from tb top with optc = %0d and optt = %0d", optc, optt), UVM_LOW);
		if(optc == 0 & optt == 0) begin
			`uvm_info("TB_TOP", "run_test is expected to run for 700 ns", UVM_LOW);
		end
		else if(optc == 0 & optt == 1) begin
			`uvm_info("TB_TOP", "run_test is expected to run for 900 ns", UVM_LOW);
		end
		else if(optc == 0 & optt == 2) begin
			`uvm_info("TB_TOP", "run_test is expected to run for 400 ns", UVM_LOW);
		end
		else if(optc == 1 & optt == 0) begin
			`uvm_info("TB_TOP", "run_test is expected to run for 700 ns", UVM_LOW);
		end
		else if(optc == 1 & optt == 1) begin
			`uvm_info("TB_TOP", "run_test is expected to exit at 0 time", UVM_LOW);
		end
		else if(optc == 1 & optt == 2) begin
			`uvm_info("TB_TOP", "run_test is expected to exit at 0 time", UVM_LOW);
		end
		else begin
			`uvm_info("TB_TOP", "run_test is expected to exit at 0 time", UVM_LOW);
		end
		uvm_config_db #(int)::set(.cntxt(null), .inst_name(""), .field_name("optc"), .value(optc));
		uvm_config_db #(int)::set(.cntxt(null), .inst_name(""), .field_name("optt"), .value(optt));
		run_test("simple_test");
	end
endmodule
