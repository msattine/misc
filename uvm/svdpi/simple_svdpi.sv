import uvm_pkg::*;
`include "uvm_macros.svh"

import "DPI-C" function int abc_compare(int x, int y);
class simple_test extends uvm_test;
	string my_name = "Test";
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		this.print();
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("Compare(12, 14) is %d", abc_compare(12, 14)), UVM_LOW);
		`uvm_info(get_name(), $sformatf("Compare(12, 12) is %d", abc_compare(12, 12)), UVM_LOW);
		`uvm_info(get_name(), $sformatf("Compare(12, 11) is %d", abc_compare(12, 11)), UVM_LOW);
		phase.drop_objection(this);
	endtask
endclass

module top();
	initial begin
		`uvm_info("TB_TOP", "Launching the test from tb top", UVM_LOW);
		run_test("simple_test");
	end
endmodule
