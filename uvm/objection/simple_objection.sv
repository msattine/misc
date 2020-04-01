import uvm_pkg::*;
`include "uvm_macros.svh"

// Example showing usage of objection class and its functions 

class simple_comp2 extends uvm_component;
	string my_name = "comp2";
	`uvm_component_utils(simple_comp2)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In build phase of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		phase.drop_objection(this);
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In connect phase of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		phase.drop_objection(this);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In run phase of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		phase.drop_objection(this);
	endtask
endclass

class simple_comp1 extends uvm_component;
	string my_name = "Comp1";
	simple_comp2 comp2;
	`uvm_component_utils(simple_comp1)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		comp2 = simple_comp2::type_id::create(.name("comp2"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In run phase of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		phase.drop_objection(this);
	endtask
endclass

class simple_test extends uvm_test;
	string my_name = "Test";
	simple_comp1 comp1;
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		comp1 = simple_comp1::type_id::create(.name("comp1"), .parent(this)); //This will create component of type simple_comp
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	function void mwrite(int iters, uvm_phase phase);
		if(iters == 0)
			return;
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In mwrite of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		mwrite(iters-1, phase);
		phase.drop_objection(this);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		phase.raise_objection(this);
		`uvm_info(get_name(), $sformatf("In run phase of %s -> objctn count = %0d", my_name, phase.phase_done.get_objection_count(this)), UVM_LOW);
		mwrite(10, phase);
		phase.drop_objection(this);
	endtask
endclass

module top();
	int opt;
	initial begin
		if(!$value$plusargs("opt=%d", opt)) //opt=1 -> override by type, opt=2 -> override by name
			opt = 0; // No override
		`uvm_info("TB_TOP", $sformatf("Launching the test from tb top with opt = %0d", opt), UVM_LOW);
		run_test("simple_test");
	end
endmodule
