import uvm_pkg::*;
`include "uvm_macros.svh"

//Example showing how to use get and set functions of uvm_config_db class.

class simple_sub_comp extends uvm_component;
	string my_name = "Sub_comp";
	int my_num;
	`uvm_component_utils(simple_sub_comp)
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
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		if(!uvm_config_db#(int)::get(.cntxt(this), .inst_name(""), .field_name("simple_var"), .value(my_num))) begin
			`uvm_info(get_name(), $sformatf("In run phase of %s: no var found", my_name), UVM_LOW);
		end
		else begin
			`uvm_info(get_name(), $sformatf("In run phase of %s: var found = %0d", my_name, my_num), UVM_LOW);
		end
		this.print();
	endtask
endclass

class simple_comp extends uvm_component;
	string my_name = "Comp";
	simple_sub_comp sub_comp;
	int my_num;
	`uvm_component_utils(simple_comp)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		sub_comp = simple_sub_comp::type_id::create(.name("sub_comp"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
		//if(!uvm_config_db#(int)::get(.cntxt(this), .inst_name(""), .field_name("simple_var"), .value(my_num))) begin
		if(!uvm_config_db#(int)::get(.cntxt(uvm_root::get()), .inst_name("uvm_test_top.comp"), .field_name("simple_var"), .value(my_num))) begin
			`uvm_info(get_name(), $sformatf("In connect phase of %s: no var found", my_name), UVM_LOW);
		end
		else begin
			`uvm_info(get_name(), $sformatf("In connect phase of %s: var found = %0d", my_name, my_num), UVM_LOW);
		end
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simple_test extends uvm_test;
	string my_name = "Test";
	simple_comp comp;
	int my_num;
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		comp = simple_comp::type_id::create(.name("comp"), .parent(this));
		if(!uvm_config_db#(int)::get(.cntxt(this), .inst_name(""), .field_name("simple_var"), .value(my_num))) begin
			`uvm_info(get_name(), $sformatf("In build phase of %s: no var found", my_name), UVM_LOW);
		end
		else begin
			`uvm_info(get_name(), $sformatf("In build phase of %s: var found = %0d", my_name, my_num), UVM_LOW);
		end
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

module top();
	int opt;
	initial begin
		if(!$value$plusargs("opt=%d", opt)) 
			opt = 0;
		`uvm_info("TB_TOP", $sformatf("Launching the test from tb top with opt = %0d", opt), UVM_LOW);
		case(opt)
			0: uvm_config_db#(int)::set(.cntxt(null), .inst_name("*"), .field_name("simple_var"), .value(4)); // Every get sees this
			1: uvm_config_db#(int)::set(.cntxt(null), .inst_name("uvm_test_top*"), .field_name("simple_var"), .value(4)); //Every get sees this
			2: uvm_config_db#(int)::set(.cntxt(null), .inst_name("uvm_test_top.*"), .field_name("simple_var"), .value(4)); //Every get other than that in Test sees this
			3: uvm_config_db#(int)::set(.cntxt(null), .inst_name("uvm_test_top.comp.*"), .field_name("simple_var"), .value(4)); //Only get in sub comp sees this
			4: uvm_config_db#(int)::set(.cntxt(null), .inst_name("uvm_test_top.comp.sub_comp.*"), .field_name("simple_var"), .value(4)); //No component sees it
			default: uvm_config_db#(int)::set(.cntxt(null), .inst_name("*"), .field_name("simple_var"), .value(4)); // Every get sees this
		endcase
		//`uvm_info("TB TOP", $sformatf("UVM CONFIG DB: %p", uvm_config_db#(int)::m_rsc[uvm_root::get()]), UVM_LOW);
		run_test("simple_test");
	end
endmodule
